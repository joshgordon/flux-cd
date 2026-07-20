# Manages the existing `cloudflare/role/dns-editor` role on the
# vault-cloudflare-secret-engine plugin (mounted at "cloudflare"). There's no
# purpose-built vault provider resource for this third-party plugin, and
# vault_generic_endpoint doesn't support `terraform import`, so this adopts
# the role by overwriting it with matching config (safe - it's an idempotent
# config write, doesn't touch already-issued tokens/leases).
#
# Only change from what was live: ttl bumped from the engine default (1h) to
# 24h, so cert-manager isn't getting a new Cloudflare token every hour.
resource "vault_generic_endpoint" "cloudflare_dns_editor_role" {
  path                 = "cloudflare/role/dns-editor"
  ignore_absent_fields = true

  data_json = jsonencode({
    token_type = "user"
    ttl        = "24h"
    policies = [
      {
        effect = "allow"
        permission_groups = [
          { name = "Account DNS Settings Write" },
          { name = "DNS Write" },
          { name = "Zone Read" },
        ]
        resources = {
          "com.cloudflare.api.account.zone.2ee0444a5f89c9c46f48f65264e4ada8" = "*"
          "com.cloudflare.api.account.zone.cb86beacfcc5f893c6c6ab59458540de" = "*"
        }
      },
    ]
  })
}

# cert-manager's Cloudflare DNS01 solver reads a token minted from the role
# above via external-secrets (see clusters/cobbler/cert-manager/). Scoped to
# read-only on just that one role's creds endpoint.
module "cert_manager_cloudflare_vault_role" {
  source = "../../modules/vault-k8s-app-role"

  app_name             = "cert-manager-cloudflare"
  namespace            = "cert-manager"
  service_account_name = "cloudflare-dns-token-reader"

  policy_rules = [
    {
      path         = "cloudflare/creds/dns-editor"
      capabilities = ["read"]
    },
  ]
}
