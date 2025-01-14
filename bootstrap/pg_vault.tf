resource "proxmox_vm_qemu" "pg_vault" {
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
  }
  provisioner "remote-exec" {
    script = "${path.module}/config/provision.sh"
  }
  provisioner "file" {
    source      = "${path.module}/config/postgres.conf"
    destination = "/var/lib/pgsql/17/data/postgresql.conf"
  }
  provisioner "file" {
    source      = "${path.module}/config/pg_hba.conf"
    destination = "/var/lib/pgsql/17/data/pg_hba.conf"
  }
  provisioner "remote-exec" {
    script = "${path.module}/config/startup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "until sudo systemctl status postgresql-17 > /dev/null 2>&1; do echo 'Waiting for PostgreSQL service...'; sleep 5; done",
      "sudo -u postgres psql -c \"ALTER SYSTEM SET password_encryption TO 'scram-sha-256';\"",
      # K3S - These should probably be template files
      "sudo -u postgres psql -c \"CREATE USER ${var.pg_user_kubernetes} WITH PASSWORD '${var.pg_password_kubernetes}'\";",
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.pg_database_kubernetes}\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.pg_database_kubernetes} TO ${var.pg_user_kubernetes};\"",
      "sudo -u postgres psql -d ${var.pg_database_kubernetes} -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_kubernetes}\"",
      # VAULT
      "sudo -u postgres psql -c \"CREATE USER ${var.pg_user_vault} WITH PASSWORD '${var.pg_password_vault}'\";",
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.pg_database_vault}\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.pg_database_vault} TO ${var.pg_user_vault};\"",
      "sudo -u postgres psql -d ${var.pg_database_vault} -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_vault}\"",
      # TERRAFORM
      "sudo -u postgres psql -c \"CREATE USER ${var.pg_user_terraform} WITH PASSWORD '${var.pg_password_terraform}'\";",
      "sudo -u postgres psql -c \"CREATE DATABASE ${var.pg_database_terraform}\"",
      "sudo -u postgres psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${var.pg_database_terraform} TO ${var.pg_user_terraform}\"",
      "sudo -u postgres psql -d ${var.pg_database_terraform} -c \"GRANT ALL ON SCHEMA public TO ${var.pg_user_terraform}\"",
      # DO I NEED THIS STILL??????????
      "echo 'host    replication     all             ::1/128                 scram-sha-256' | sudo tee -a /var/lib/pgsql/17/data/pg_hba.conf",
      "echo 'host    all    all                      0.0.0.0/0               scram-sha-256' | sudo tee -a /var/lib/pgsql/17/data/pg_hba.conf",
      "sudo systemctl restart postgresql-17"
    ]
  }
}

output "pg_vault_ip" {
  value = split("/", var.pg_vault_ip)[0]
}
