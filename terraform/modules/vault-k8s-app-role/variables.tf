variable "app_name" {
  description = "Name of the app. Used as the Vault policy name and (by default) the k8s service account name."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace the app runs in."
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account the app runs as. Defaults to app_name."
  type        = string
  default     = null
}

variable "backend" {
  description = "Mount path of the kubernetes auth backend."
  type        = string
  default     = "kubernetes"
}

variable "audience" {
  description = <<-EOT
    Audience claim to verify in the presented JWT. Leave empty (default) unless
    the consuming identity explicitly requests a custom-audience token via its
    own TokenRequest call - a pod's default projected service account token
    (e.g. what a plain `file("/var/run/secrets/.../token")` read gets you) has
    no custom audience, so setting this would just make Vault reject it with
    "invalid audience (aud) claim". cert-manager's vault-issuer role is the
    one existing exception (it requests audience "vault://gordns-cobbler"
    itself) - that role is hand-managed outside this module.
  EOT
  type        = string
  default     = ""
}

variable "token_ttl" {
  description = "TTL, in seconds, of tokens issued to this role."
  type        = number
  default     = 300
}

variable "policy_rules" {
  description = "Vault policy rules granted to this app."
  type = list(object({
    path         = string
    capabilities = list(string)
  }))
}
