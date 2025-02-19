provider "onepassword" {
  account = "my.1password.eu"
}

data "onepassword_vault" "vault" {
  name = "Personal"
}

data "onepassword_item" "cloudflare_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "cloudflare-fzx-infra-domain-edit"
}

data "onepassword_item" "hcloud_token" {
  vault = data.onepassword_vault.vault.uuid
  title = "hcloud-token-staging"
}

data "onepassword_item" "zot_admin" {
  vault = data.onepassword_vault.vault.uuid
  title = "zot-admin-user"
}

data "onepassword_item" "zot_pull_user" {
  vault = data.onepassword_vault.vault.uuid
  title = "zot-pull-user"
}

data "onepassword_item" "zot_push_user" {
  vault = data.onepassword_vault.vault.uuid
  title = "zot-push-user"
}

data "onepassword_item" "aws_credentials" {
  vault = data.onepassword_vault.vault.uuid
  title = "hetzner-object-store-staging"
}

resource "htpasswd_password" "zot_admin" {
  password = data.onepassword_item.zot_admin.password
}

resource "htpasswd_password" "zot_pull_user" {
  password = data.onepassword_item.zot_pull_user.password
}

resource "htpasswd_password" "zot_push_user" {
  password = data.onepassword_item.zot_push_user.password
}

locals {
  htpasswd = join("\n",["admin:${htpasswd_password.zot_admin.bcrypt}",
    "pull-user:${htpasswd_password.zot_pull_user.bcrypt}",
    "push-user:${htpasswd_password.zot_push_user.bcrypt}"],
  )
}
provider "hcloud" {
    token = data.onepassword_item.hcloud_token.password
}

provider "cloudflare" {
  api_token = data.onepassword_item.cloudflare_token.password
}

variable "ssh_key" {
    type = string
    description = "The SSH key to use for the Hetzner Cloud servers"
    default = "~/.ssh/harbor.pub"
}

variable "zot_version" {
    type = string
    description = "The version of Zot to deploy"
    default = "v2.1.2"
}

data "http" "current_ipv4" {
  url   = "https://ipv4.icanhazip.com"

  retry {
    attempts     = 10
    min_delay_ms = 1000
    max_delay_ms = 1000
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "HTTP status code invalid"
    }
  }
}

resource "hcloud_firewall" "registry" {
  name = "registry"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "${chomp(data.http.current_ipv4.response_body)}/32",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port = "22"
    source_ips = [
      "${chomp(data.http.current_ipv4.response_body)}/32",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_ssh_key" "registry_ssh_key" {
  name       = "registry"
  public_key = file(var.ssh_key)
}

data "cloudinit_config" "registry" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/cloud-init.yaml", {
      sshPublicKey = file(var.ssh_key)
      zotConfig = file("${path.module}/zot-config.json")
      zotHtpasswd = local.htpasswd
      zotVersion = var.zot_version
      awsAccessKeyId = data.onepassword_item.aws_credentials.section[0].field[0].value
      awsSecretAccessKey = data.onepassword_item.aws_credentials.section[0].field[1].value
    })
  }
}

resource "hcloud_server" "registry" {
  name               = "registry"
  image              = "ubuntu-24.04"
  server_type        = "cax11"
  location           = "hel1"
  ssh_keys           = [hcloud_ssh_key.registry_ssh_key.id]
  firewall_ids = [hcloud_firewall.registry.id]
  backups            = false
  user_data          = data.cloudinit_config.registry.rendered
  labels = {
    "k8s" = "registry"
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

data "cloudflare_zones" "example_zones" {
  name = "fzx-infra.dev"
}

data "cloudflare_zone" "zone" {
  zone_id = data.cloudflare_zones.example_zones.result[0].id
}

resource "cloudflare_dns_record" "registry_ipv4" {
  name    = "registry.fzx-infra.dev"
  ttl     = 3600
  type    = "A"
  zone_id = data.cloudflare_zone.zone.zone_id
  content = hcloud_server.registry.ipv4_address
}

resource "cloudflare_dns_record" "registry_ipv6" {
  name    = "registry.fzx-infra.dev"
  ttl     = 3600
  type    = "AAAA"
  zone_id = data.cloudflare_zone.zone.zone_id
  content = hcloud_server.registry.ipv6_address
}

output "zone_id" {
  value = data.cloudflare_zone.zone
}
output "cloudinit" {
  value = data.cloudinit_config.registry.rendered
  sensitive = true
}
