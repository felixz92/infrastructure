variable "ssh_key" {
    type = string
    description = "The SSH key to use for the Hetzner Cloud servers"
    default = "~/.ssh/harbor.pub"
}

resource "hcloud_ssh_key" "harbor_ssh_key" {
  name       = "harbor"
  public_key = file(var.ssh_key)
}

data "cloudinit_config" "harbor" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/cloud-init.yaml", {
      sshPublicKey = file(var.ssh_key)
    })
  }
}

resource "hcloud_server" "harbor" {
  name               = "harbor"
  image              = "ubuntu-24.04"
  server_type        = "cx22"
  location           = "hel1"
  ssh_keys           = [hcloud_ssh_key.harbor_ssh_key.id]
  backups            = false
  user_data          = data.cloudinit_config.harbor.rendered
  labels = {
    "k8s" = "harbor"
  }
  lifecycle {
    ignore_changes = [
      location,
      ssh_keys,
      user_data,
      image,
    ]
  }
}
