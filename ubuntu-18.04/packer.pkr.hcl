variable "version" {
  type    = string
  default = "18.04"
}

variable "baseurl" {
  type    = string
  default = "http://cdimage.ubuntu.com/releases"
}
variable "output_dir" {
  type    = string
  default = "output"
}

variable "output_name" {
  type    = string
  default = "ubuntu.qcow2"
}

locals {
  source_checksum_url = "file:${var.baseurl}/${var.version}/release/SHA256SUMS"
  source_iso = "${var.baseurl}/${var.version}/release/ubuntu-${var.version}.5-server-amd64.iso"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

# "timestamp" template function replacement
locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}


build {
  description = <<EOF
This builder builds a QEMU image from a ubuntu "netinst" CD ISO file.
It contains a few basic tools and can be use as a "cloud image" alternative.
EOF

  sources = ["source.qemu.ubuntu"]

  provisioner "file" {
    destination = "/tmp/configure-qemu-image.sh"
    source      = "configure-qemu-image.sh"
  }

  provisioner "shell" {
    inline = [
      "sh -cx 'sudo bash /tmp/configure-qemu-image.sh'"
    ]
  }

  post-processor "manifest" {
    keep_input_artifact = true
  }

  post-processor "shell-local" {
    keep_input_artifact = true
    inline = [
      "./post-process.sh ${var.output_dir}/${var.output_name}"
    ]
  }
}


source qemu "ubuntu" {
  iso_url      = "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/mini.iso"
  iso_checksum = "bed8a55ae2a657f8349fe3271097cff3a5b8c3d1048cf258568f1601976fa30d"

  cpus = 2
  # The ubuntu installer warns with a dialog box if there's not enough memory
  # in the system.
  memory      = 2000
  disk_size   = 8000
  accelerator = "kvm"

  headless = "false"

  # Serve the `http` directory via HTTP, used for preseeding the ubuntu installer.
  http_directory = "http"
  http_port_min  = 9990
  http_port_max  = 9999

  # SSH ports to redirect to the VM being built
  host_port_min = 2222
  host_port_max = 2229
  # This user is configured in the preseed file.
  ssh_password     = "${var.ssh_password}"
  ssh_username     = "${var.ssh_username}"
  ssh_pty          = "true"
  ssh_wait_timeout = "10000s"

  shutdown_command = "echo '${var.ssh_password}'  | sudo -S /sbin/shutdown -hP now"

  # Builds a compact image
  disk_compression   = true
  disk_discard       = "unmap"
  skip_compaction    = false
  disk_detect_zeroes = "unmap"

  format           = "qcow2"
  output_directory = "${var.output_dir}"
  vm_name          = "${var.output_name}"

  boot_wait = "1s"
  boot_command = [
  "<tab><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
        "net.ifnames=0 biosdevname=0 fb=false hostname=ubuntu locale=en_US ",
        "console-keymaps-at/keymap=us console-setup/ask_detect=false ",
        "console-setup/layoutcode=us keyboard-configuration/layout=USA keyboard-configuration/variant=USA ",
        "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <enter><wait>"

  ]
}
