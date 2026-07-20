resource "vault_policy" "this" {
  name = var.app_name

  policy = join("\n\n", [
    for rule in var.policy_rules : <<-EOT
      path "${rule.path}" {
        capabilities = ${jsonencode(rule.capabilities)}
      }
    EOT
  ])
}

resource "vault_kubernetes_auth_backend_role" "this" {
  backend                          = var.backend
  role_name                        = "${var.app_name}-role"
  bound_service_account_names      = [coalesce(var.service_account_name, var.app_name)]
  bound_service_account_namespaces = [var.namespace]
  audience                         = var.audience
  token_ttl                        = var.token_ttl
  token_policies                   = [vault_policy.this.name]
}
