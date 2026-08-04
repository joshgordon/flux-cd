# Placeholder KV paths - narrow these once it's clear which secrets
# external-secrets actually needs to read from OpenBao.
module "external_secrets_vault_role" {
  source = "../../modules/vault-k8s-app-role"

  app_name  = "external-secrets"
  namespace = "external-secrets"
  # Not "external-secrets" - see the comment in
  # clusters/cobbler/external-secrets/vault-secret-store.yml.
  service_account_name = "external-secrets-external-secrets"

  policy_rules = [
    {
      path         = "secret/data/external-secrets/*"
      capabilities = ["read"]
    },
    {
      path         = "secret/metadata/external-secrets/*"
      capabilities = ["read", "list"]
    },
  ]
}

# Backs the OpenBao agent injector annotations on the grafana-alloy DaemonSet
# (see clusters/cobbler/grafana-cloud/grafana-cloud.yml) - Alloy reads its
# Grafana Cloud remote_write/Loki credentials from files the injector writes,
# rather than through an ExternalSecret.
module "grafana_alloy_vault_role" {
  source = "../../modules/vault-k8s-app-role"

  app_name  = "grafana-alloy"
  namespace = "grafana-cloud"

  policy_rules = [
    {
      path         = "secret/data/grafana-cloud"
      capabilities = ["read"]
    },
  ]
}
