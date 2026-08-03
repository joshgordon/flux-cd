# flux-cd

## Terraform

Terraform under `terraform/environments/*` is wired up through Flux's terraform-controller, not applied locally. To make a change:

1. Commit and push the `.tf` change to `main`.
2. The controller picks up the diff and generates a plan.
3. Josh reviews and approves the plan himself (via the Terraform CR / UI).

Do not run `terraform apply` (or `terraform plan`) locally against this repo's state, and don't offer to — that's not how changes land here. After a change is approved and applied, verify it went live by reading the actual resource state (e.g. `bao read <path>` for Vault/OpenBao, `kubectl get <resource> -o yaml` for cluster objects) rather than assuming the commit alone means it's live.
