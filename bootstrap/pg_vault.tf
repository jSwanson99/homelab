resource "proxmox_vm_qemu" "pg_vault" {
  #{{{
  name        = "pg-vault"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0 = "ip=${var.pg_vault_ip},gw=${var.gateway_ip}"
  ciuser    = var.user
  sshkeys   = <<EOF
${file("~/.ssh/id_ed25519.pub")}
EOF

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "32G"
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
      ide2 {
        cdrom {
          iso = "local:iso/Rocky-9.4-x86_64-minimal.iso"
        }
      }
    }
  }
  network {
    firewall = true
    bridge   = "vmbr0"
    model    = "virtio"
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.pg_vault_ip)[0]
  } # }}}

  provisioner "remote-exec" {
    script = "${path.module}/config/provision.sh"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.postgres.cert_pem
    destination = "/etc/ssl/certs/postgres.crt"
  }
  provisioner "file" {
    content     = tls_private_key.postgres.private_key_pem
    destination = "/etc/ssl/certs/postgres.key"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.vault.cert_pem
    destination = "/etc/ssl/certs/vault.crt"
  }
  provisioner "file" {
    content     = tls_private_key.vault.private_key_pem
    destination = "/etc/ssl/certs/vault.key"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 600 /etc/ssl/certs/postgres.key", # Only owner can read/write
      "sudo chown postgres:postgres /etc/ssl/certs/postgres.key",
      "sudo chown postgres:postgres /etc/ssl/certs/postgres.crt",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/config/postgres.conf"
    destination = "/var/lib/pgsql/17/data/postgresql.conf"
  }
  provisioner "file" {
    source      = "${path.module}/config/pg_hba.conf"
    destination = "/var/lib/pgsql/17/data/pg_hba.conf"
  }
  provisioner "file" {
    content = templatefile("${path.module}/config/vault.hcl", {
      pg_database_vault = var.pg_database_vault
      pg_password_vault = var.pg_password_vault
      pg_user_vault     = var.pg_user_vault
      pg_vault_ip       = var.pg_vault_ip
    })
    destination = "/etc/vault.d/vault.hcl"
  }
  provisioner "file" {
    source      = "${path.module}/config/vault.sql"
    destination = "/etc/vault.d/vault.sql"
  }
  provisioner "remote-exec" {
    script = "${path.module}/config/start_postgres.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "until sudo systemctl status postgresql-17 > /dev/null 2>&1; do echo 'Waiting for PostgreSQL service...'; sleep 5; done",
      "sudo -u postgres psql -c \"ALTER SYSTEM SET password_encryption TO 'scram-sha-256';\"",
      # VAULT
      "sudo -u postgres psql -c \"CREATE USER ${var.pg_user_vault} WITH PASSWORD '${var.pg_password_vault}'\";",
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.pg_database_vault}\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.pg_database_vault} TO ${var.pg_user_vault};\"",
      "sudo -u postgres psql -d ${var.pg_database_vault} -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_vault}\"",
      "sudo -u postgres psql -d ${var.pg_database_vault} -f /etc/vault.d/vault.sql",
      # TERRAFORM
      "sudo -u postgres psql -c \"CREATE USER ${var.pg_user_terraform} WITH PASSWORD '${var.pg_password_terraform}'\";",
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.pg_database_terraform}\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.pg_database_terraform} TO ${var.pg_user_terraform}\"",
      "sudo -u postgres psql -d ${var.pg_database_terraform} -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_terraform}\"",
      # So TF user can be used with PG provider
      "sudo -u postgres psql -c \"ALTER ROLE ${var.pg_user_terraform} WITH CREATEROLE CREATEDB;\"",
      "sudo -u postgres psql -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_terraform} WITH GRANT OPTION;\"",
      "sudo -u postgres psql -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${var.pg_user_terraform} WITH GRANT OPTION;\"",
      # DO I NEED THIS STILL??????????
      "echo 'host    replication     all             ::1/128                 scram-sha-256' | sudo tee -a /var/lib/pgsql/17/data/pg_hba.conf",
      "echo 'host    all    all                      0.0.0.0/0               scram-sha-256' | sudo tee -a /var/lib/pgsql/17/data/pg_hba.conf",
      "sudo systemctl restart postgresql-17",
    ]
  }
  provisioner "remote-exec" {
    script = "${path.module}/config/start_vault.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/config/setup-psql-vault.sh", {
      pg_database_vault = var.pg_database_vault
      pg_password_vault = var.pg_password_vault
      pg_user_vault     = var.pg_user_vault
      pg_vault_ip       = var.pg_vault_ip
    })
    destination = "/tmp/setup-psql-vault.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "systemctl is-active vault --wait",
      "chmod +x /tmp/setup-psql-vault.sh",
      "bash /tmp/setup-psql-vault.sh"
    ]
  }
}
data "external" "unsealkeysisnecure" {
  depends_on = [proxmox_vm_qemu.pg_vault]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "root@${split("/", var.pg_vault_ip)[0]}",
    "cat /tmp/secret.json | jq -c '{keys: (.unseal_keys_b64 | join(\",\")), token: .root_token}'"
  ]
}
output "vault_unseal_keys" {
  value = data.external.unsealkeysisnecure.result.keys
}

output "vault_root_token" {
  value = data.external.unsealkeysisnecure.result.token
}


# {{{
output "pg_vault_ip" {
  value = split("/", var.pg_vault_ip)[0]
}

resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "vault" {
  private_key_pem = tls_private_key.vault.private_key_pem
  subject {
    common_name  = "vault"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  dns_names    = ["localhost"]
  ip_addresses = ["127.0.0.1", split("/", var.pg_vault_ip)[0]]
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem      = tls_cert_request.vault.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem
  ca_cert_pem           = var.ca_cert_pem
  validity_period_hours = 43800
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "tls_private_key" "postgres" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "postgres" {
  private_key_pem = tls_private_key.postgres.private_key_pem
  subject {
    common_name  = "postgres"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.pg_vault_ip)[0]]
}

resource "tls_locally_signed_cert" "postgres" {
  cert_request_pem      = tls_cert_request.postgres.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem
  ca_cert_pem           = var.ca_cert_pem
  validity_period_hours = 43800
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

# }}}
