resource "proxmox_vm_qemu" "ebpf_dev" {
  name        = "ebpf-dev"
    target_node = "pve"

    ipconfig0   = "ip=dhcp"

    disks {
      ide {
        ide2 {
          cdrom {
            iso = "local:iso/Rocky-9.4-x86_64-minimal.iso"
          }
        }
      }
    }

  provisioner "remote-exec" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf groupinstall 'Development Tools' -y",
      "sudo dnf install epel-release -y",
# Install required packages for eBPF development
      "sudo dnf install -y clang llvm",
      "sudo dnf install -y elfutils-libelf-devel",
      "sudo dnf install -y bpftool",
      "sudo dnf install -y libbpf-devel",
      "sudo dnf install -y bcc-tools",
      "sudo dnf install -y kernel-devel-$(uname -r)",
      "sudo dnf install -y kernel-headers-$(uname -r)",
# Set up debugfs and tracefs
      "sudo mkdir -p /sys/kernel/debug",
      "sudo mount -t debugfs debugfs /sys/kernel/debug",
      "sudo mkdir -p /sys/kernel/tracing",
      "sudo mount -t tracefs tracefs /sys/kernel/tracing",
# Add mountpoints to /etc/fstab for persistence
      "echo 'debugfs /sys/kernel/debug debugfs defaults 0 0' | sudo tee -a /etc/fstab",
      "echo 'tracefs /sys/kernel/tracing tracefs defaults 0 0' | sudo tee -a /etc/fstab",
# Verify BPF functionality
      "sudo sysctl kernel.bpf_stats_enabled=1",
# Optional: Install additional tools
      "sudo dnf install -y bpftrace",
# Set up environment variables
      "echo 'export LLC=llc' | sudo tee -a /etc/profile.d/ebpf.sh",
      "echo 'export CLANG=clang' | sudo tee -a /etc/profile.d/ebpf.sh"
        ]
  }
}

output "vm_ip" {
  value = proxmox_vm_qemu.ebpf_dev.default_ipv4_address
    description = "The IP address of the eBPF development VM"
}
