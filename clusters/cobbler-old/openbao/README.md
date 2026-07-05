# Manual set up required.


First, disable TLS in openbao, then bootstrap:
```
k exec -it -n openbao openbao-openbao-0 -- sh
# You can tune number of keys and threshold here
vault operator init -n 1 -t 1
# copy the unseal key, save it somewhere safe.
vault operator unseal
# enter unseal key

# for nodes 2-3, exec in:
vault operator raft join http://openbao-openbao-0.openbao-openbao-internal:8200
vault operator unseal
```

Set up PKI auth.

```
bao secrets enable pki
bao secrets tune -max-lease-ttl=87600h pki
bao write -field=csr pki/intermediate/generate/internal \
    common_name="OpenBao Intermediate Authority" \
    ttl="43800h" \
    > pki_intermediate.csr
```

take that `pki_intermediate.csr` and sign it:

```
step certificate sign openbao-csr.pem ./root_ca.crt ../secrets/root_ca_key --profile intermediate-ca --not-after=8760h > openbao.pem
```

take the certificate, append the root_ca to the end of it and load it back into openbao:

```
bao write pki/intermediate/set-signed certificate=@signed_certificate.pem
```

Create the role for generating certs: (you can do this in the UI too)

```
bao write pki/roles/example-dot-com \
    allowed_domains="example.com" \
    allow_subdomains=true \
    max_ttl="720h"
```


## Setting up k8s auth

```
bao auth enable -path=kubernetes kubernetes
kubectl config view --minify --flatten -ojson \
  | jq -r '.clusters[].cluster."certificate-authority-data"' \
  | base64 -d >/tmp/cacrt
bao write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default \
    kubernetes_ca_cert=@/tmp/cacrt
```

```hcl
# Policy name: cert-manager
# cobbler-gordns-net should match your pki role name.
path "pki/sign/cobbler-gordns-net" {
  capabilities = ["create", "update"]
}

path "pki/issue/cobbler-gordns-net" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}
```

save this as policy.hcl and run:

```
bao policy write cert-manager policy.hcl
```

Ok almost there....

```
bao write auth/kubernetes/role/vault-issuer-role bound_service_account_names=vault-issuer bound_service_account_namespaces=cert-manager audience="vault://gordns-cobbler" policies=default,cert-manager ttl=1m
```

At this point you should be able to `k apply -f cert.yml`, and it should generate a cert for you.
