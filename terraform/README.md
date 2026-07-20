# Terraform (applied via tofu-controller)

This directory is reconciled by [tofu-controller](https://github.com/flux-iac/tofu-controller),
not run locally. See `clusters/cobbler/tofu-controller/` for the controller
HelmRelease and the `Terraform` custom resource that points at
`environments/cobbler`.

```
modules/vault-k8s-app-role/   reusable module: one Vault policy + one k8s
                               auth backend role, bound to an app's service
                               account
environments/cobbler/         one module call per app that needs OpenBao
                               access
```

Adding access for a new app is one module block in
`environments/cobbler/main.tf`:

```hcl
module "my_app_vault_role" {
  source = "../../modules/vault-k8s-app-role"

  app_name              = "my-app"
  namespace             = "my-app"
  service_account_name  = "my-app"

  policy_rules = [
    {
      path         = "secret/data/my-app/*"
      capabilities = ["read"]
    },
  ]
}
```

## Plans require manual approval

`clusters/cobbler/tofu-controller/terraform.yml` sets `approvePlan: ""` -
nothing is applied automatically. After pushing a change:

1. Wait for the controller to plan, then check status:
   ```
   kubectl -n flux-system get tf/cobbler -o yaml
   ```
   The pending plan's id is under `status.plan.pending` (also visible via
   `kubectl -n flux-system describe tf/cobbler`).
2. Review the plan (surfaced in the `Terraform` object's events/conditions,
   or `flux logs --kind=Terraform` for the runner's own plan output).
3. If it looks right, set `spec.approvePlan` in `terraform.yml` to that plan
   id, commit, and push. The controller applies on the next reconcile.

Bootstrap prerequisite: the tofu-controller runner needs its own Vault
identity before any of this works - see the "Bootstrapping
terraform-controller" section in `clusters/cobbler/openbao/README.md`.
