[package]
name = "kcl"
edition = "v0.11.0"
version = "0.0.1"

[dependencies]
crossplane = "1.17.3"
crossplane_authentik = { oci = "oci://ghcr.io/felixz92/crossplane-provider-authentik/crossplane-authetik:0.5.0", tag = "0.5.0", version = "0.5.0" }
k8s = "1.31.2"
