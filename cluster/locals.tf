locals {
  ssh_public_key = file(var.ssh_public_key)
  ssh_private_key = file(var.ssh_private_key)
}
