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
  description = "Audience claim to verify in the projected service account JWT. Must match what the app's Kubernetes auth config requests."
  type        = string
  default     = "vault://gordns-cobbler"
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
