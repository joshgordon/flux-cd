terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }
}

variable "vault_address" {
  description = "OpenBao/Vault API address."
  type        = string
  default     = "https://vault.cobbler.gordns.net"
}

variable "vault_k8s_auth_role" {
  description = "Kubernetes auth role the tofu-controller runner itself authenticates as."
  type        = string
  default     = "terraform-controller"
}

provider "vault" {
  address = var.vault_address

  # The tf-runner pod authenticates as itself via its own projected service
  # account token - see the "terraform-controller" bootstrap block in
  # clusters/cobbler/openbao/README.md for how that role/policy is granted.
  # This can't be created by this same Terraform config (chicken-and-egg).
  auth_login {
    path = "auth/kubernetes/login"
    parameters = {
      role = var.vault_k8s_auth_role
      jwt  = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
    }
  }
}
