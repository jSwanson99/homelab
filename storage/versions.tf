terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
    truenas = {
      source  = "dariusbakunas/truenas"
      version = "0.11.1"
    }
  }
}
