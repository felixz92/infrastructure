data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "kube-hetzner" {
  providers = {
    hcloud = hcloud
  }
  hcloud_token = var.hcloud_token != "" ? var.hcloud_token : ""
  source = "kube-hetzner/kube-hetzner/hcloud"
  version = "2.16.0"
  ssh_public_key = local.ssh_public_key
  ssh_private_key = local.ssh_private_key
  network_region = "eu-central" # change to `us-east` if location is ash


  # For the control planes, at least three nodes are the minimum for HA. Otherwise, you need to turn off the automatic upgrades (see README).
  # **It must always be an ODD number, never even!** Search the internet for "split-brain problem with etcd" or see https://rancher.com/docs/k3s/latest/en/installation/ha-embedded/
  # For instance, one is ok (non-HA), two is not ok, and three is ok (becomes HA). It does not matter if they are in the same nodepool or not! So they can be in different locations and of various types.

  # Of course, you can choose any number of nodepools you want, with the location you want. The only constraint on the location is that you need to stay in the same network region, Europe, or the US.
  # For the server type, the minimum instance supported is cx22. The cax11 provides even better value for money if your applications are compatible with arm64; see https://www.hetzner.com/cloud.

  # IMPORTANT: Before you create your cluster, you can do anything you want with the nodepools, but you need at least one of each, control plane and agent.
  # Once the cluster is up and running, you can change nodepool count and even set it to 0 (in the case of the first control-plane nodepool, the minimum is 1).
  # You can also rename it (if the count is 0), but do not remove a nodepool from the list.

  # You can safely add or remove nodepools at the end of each list. That is due to how subnets and IPs get allocated (FILO).
  # The maximum number of nodepools you can create combined for both lists is 50 (see above).
  # Also, before decreasing the count of any nodepools to 0, it's essential to drain and cordon the nodes in question. Otherwise, it will leave your cluster in a bad state.

  # Before initializing the cluster, you can change all parameters and add or remove any nodepools. You need at least one nodepool of each kind, control plane, and agent.
  # ⚠️ The nodepool names are entirely arbitrary, but all lowercase, no special characters or underscore (dashes are allowed), and they must be unique.

  # If you want to have a single node cluster, have one control plane nodepools with a count of 1, and one agent nodepool with a count of 0.

  # Please note that changing labels and taints after the first run will have no effect. If needed, you can do that through Kubernetes directly.

  # Multi-architecture clusters are OK for most use cases, as container underlying images tend to be multi-architecture too.

  # * Example below:

  control_plane_nodepools = [
    {
      name        = "control-plane-fsn1",
      server_type = "cax21",
      location    = "fsn1",
      labels      = [],
      taints      = [],
      count       = 1
    },
    {
      name        = "control-plane-nbg1",
      server_type = "cax21",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 1
    },
    {
      name        = "control-plane-hel1",
      server_type = "cax21",
      location    = "hel1",
      labels      = [],
      taints      = [],
      count       = 1
    }
  ]

  agent_nodepools = [
    {
      name        = "agent-large",
      server_type = "cax31",
      location    = "nbg1",
      labels      = [],
      taints      = [],
      count       = 0
    },
  ]
  # Add custom control plane configuration options here.
  # E.g to enable monitoring for etcd, proxy etc:
  control_planes_custom_config = {
    etcd-expose-metrics         = true,
    kube-controller-manager-arg = "bind-address=0.0.0.0",
    kube-proxy-arg              = "metrics-bind-address=0.0.0.0",
    kube-scheduler-arg          = "bind-address=0.0.0.0",
  }

  load_balancer_type     = "lb11"
  load_balancer_location = "fsn1"

  # To enable Hetzner Storage Box support, you can enable csi-driver-smb, default is "false".
  # enable_csi_driver_smb = true
  # If you want to specify the version for csi-driver-smb, set it below - otherwise it'll use the latest version available.
  # See https://github.com/kubernetes-csi/csi-driver-smb/releases for the available versions.
  # csi_driver_smb_version = "v1.16.0"

  # If you want to use a specific Hetzner CCM and CSI version, set them below; otherwise, leave them as-is for the latest versions.
  # See https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases for the available versions.
  # hetzner_ccm_version = ""
  # See https://github.com/hetznercloud/csi-driver/releases for the available versions.
  # hetzner_csi_version = ""

  # If you want to specify the Kured version, set it below - otherwise it'll use the latest version available.
  # See https://github.com/kubereboot/kured/releases for the available versions.
  # kured_version = ""

  # If you want to configure additional arguments for traefik, enter them here as a list and in the form of traefik CLI arguments; see https://doc.traefik.io/traefik/reference/static-configuration/cli/
  # They are the options that go into the additionalArguments section of the Traefik helm values file.
  # We already add "providers.kubernetesingress.ingressendpoint.publishedservice" by default so that Traefik works automatically with services such as External-DNS and ArgoCD.
  # Example:
  # traefik_additional_options = ["--log.level=DEBUG", "--tracing=true"]

  # By default traefik image tag is an empty string which uses latest image tag.
  # The default is "".
  # traefik_image_tag = "v3.0.0-beta5"

  allow_scheduling_on_control_plane = true

  system_upgrade_use_drain = true
  system_upgrade_enable_eviction = false

  initial_k3s_channel = "v1.30"

  cluster_name = var.environment

  # Extra k3s registries. This is useful if you have private registries and you want to pull images without additional secrets.
  # Or if you want to proxy registries for various reasons like rate-limiting.
  # It will create the registries.yaml file, more info here https://docs.k3s.io/installation/private-registry.
  # Note that you do not need to get this right from the first time, you can update it when you want during the life of your cluster.
  # The default is blank.
  /* k3s_registries = <<-EOT
    mirrors:
      hub.my_registry.com:
        endpoint:
          - "hub.my_registry.com"
    configs:
      hub.my_registry.com:
        auth:
          username: username
          password: password
  EOT */

  # Structured authentication configuration. Multiple authentication providers support requires v1.30+ of
  # kubernetes.
  # https://kubernetes.io/docs/reference/access-authn-authz/authentication/#using-authentication-configuration
  #
  # authentication_config = <<-EOT
  #   apiVersion: apiserver.config.k8s.io/v1beta1
  #   kind: AuthenticationConfiguration
  #   jwt:
  #   - issuer:
  #       url: "https://token.actions.githubusercontent.com"
  #       audiences:
  #       - "https://github.com/octo-org"
  #     claimMappings:
  #       username:
  #         claim: sub
  #         prefix: "gh:"
  #       groups:
  #         claim: repository_owner
  #         prefix: "gh:"
  #     claimValidationRules:
  #     - claim: repository
  #       requiredValue: "octo-org/octo-repo"
  #     - claim: "repository_visibility"
  #       requiredValue: "public"
  #     - claim: "ref"
  #       requiredValue: "refs/heads/main"
  #     - claim: "ref_type"
  #       requiredValue: "branch"
  #   - issuer:
  #       url: "https://your.oidc.issuer"
  #       audiences:
  #       - "oidc_client_id"
  #     claimMappings:
  #       username:
  #         claim: oidc_username_claim
  #         prefix: "oidc:"
  #       groups:
  #         claim: oidc_groups_claim
  #         prefix: "oidc:"
  #   EOT

  firewall_kube_api_source = ["${chomp(data.http.myip.response_body)}/32"]

  firewall_ssh_source = ["${chomp(data.http.myip.response_body)}/32"]

  extra_firewall_rules = [
    {
      description     = "To allow FluxCD access to resources via SSH"
      direction       = "out"
      protocol        = "tcp"
      port            = "22"
      source_ips      = [] # Won't be used for this rule
      destination_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      description     = "Allow Incoming Requests to Hubble Server & Hubble Relay (Cilium)"
      direction       = "in"
      protocol        = "tcp"
      port            = "4244-4245"
      source_ips      = [var.network_ipv4_cidr]
      destination_ips = []
    }
  ]
  cni_plugin = "cilium"
  cilium_version = "1.16.5"

  # Set native-routing mode ("native") or tunneling mode ("tunnel"). Default: tunnel
  cilium_routing_mode = "native"
  cilium_hubble_enabled = true

  # Configures the list of Hubble metrics to collect.
  cilium_hubble_metrics_enabled = [
    "policy:sourceContext=app|workload-name|pod|reserved-identity;destinationContext=app|workload-name|pod|dns|reserved-identity;labelsContext=source_namespace,destination_namespace"
  ]

  disable_kube_proxy = true

  # IP Addresses to use for the DNS Servers, the defaults are the ones provided by Hetzner https://docs.hetzner.com/dns-console/dns/general/recursive-name-servers/.
  # The number of different DNS servers is limited to 3 by Kubernetes itself.
  # It's always a good idea to have at least 1 IPv4 and 1 IPv6 DNS server for robustness.
  dns_servers = [
    "1.1.1.1",
    "8.8.8.8",
    "2606:4700:4700::1111",
  ]

  additional_tls_sans = ["kube.${var.base_domain}"]

   lb_hostname = var.base_domain

  # Extra commands to be executed after the `kubectl apply -k` (useful for post-install actions, e.g. wait for CRD, apply additional manifests, etc.).
  extra_kustomize_deployment_commands = <<-EOT
    kubectl apply -k https://github.com/FelixZ92/infrastructure.git/flux/staging/flux-system
  EOT

  # Extra values that will be passed to the `extra-manifests/kustomization.yaml.tpl` if its present.
  extra_kustomize_parameters = {
    environment : var.environment
    base_domain: var.base_domain
    lets_encrypt_email: var.lets_encrypt_email
    flux_public_key: base64encode(tls_private_key.main.public_key_openssh)
    flux_private_key: base64encode(tls_private_key.main.private_key_pem)
    flux_ssh_known_hosts: base64encode(file(".ssh/known_hosts"))
  }

  create_kubeconfig = false

  # Don't create the kustomize backup. This can be helpful for automation.
  # create_kustomization = false
  export_values = true
}
