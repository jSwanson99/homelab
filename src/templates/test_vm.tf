resource "proxmox_vm_qemu" "test" {
  name = "test"
  target_node = "pve"
  clone = "rocky-templ-vm"
  cores = 2
  memory = 2048
  scsihw = "virtio-scsi-single"
  os_type = "cloud-init"

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
        disk {
          storage = "local-lvm"
          size = "500M"  # CloudInit drive
        }
      }
      ide2 {
        cdrom {
          iso = "local:iso/Rocky-9.4-x86_64-minimal.iso"
        }
      }
    }
  }
}
