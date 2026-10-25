# CrowdSec on cobbler (Cilium Gateway API)

Drop this folder in as `clusters/cobbler/crowdsec/`. It runs CrowdSec
(agent + LAPI + AppSec) in the `crowdsec` namespace and the community
Envoy ext_authz bouncer, which Cilium's gateway calls through the Gateway
API `ExternalAuth` HTTPRoute filter.

| File | What it is |
|---|---|
| `namespace.yml` | `crowdsec` namespace |
| `repositories.yml` | CrowdSec HelmRepository + bouncer OCIRepository (pinned 0.8.2) |
| `crowdsec-helmrelease.yml` | CrowdSec: reads `cilium-envoy` logs, AppSec on :7422 |
| `bouncer-helmrelease.yml` | Bouncer: gRPC ext_authz on :8080 |
| `referencegrant.yml` | Lets HTTPRoutes in other namespaces point at the bouncer |
| `crowdsec-keys.secret.yml.example` | Secret template, **not** applied by Flux |

## Rollout order

1. **Create the secret** (encrypted with SOPS or by hand) before merging,
   or the LAPI and bouncer pods will fail to start.
2. **Merge without touching any HTTPRoutes.** Nothing is enforced yet.
3. **Check detection** (logs → CrowdSec):

   ```sh
   kubectl -n crowdsec get pods
   kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli bouncers list   # envoy should be listed
   kubectl -n crowdsec exec ds/crowdsec-agent -- cscli metrics show acquisition parsers
   ```

   Then from a **public** IP (private ranges are whitelisted by default):

   ```sh
   curl -I https://<a-host-behind-the-gateway>/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl
   kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli alerts list -s crowdsecurity/http-generic-test
   ```

   The alert's source IP must be your real public IP. If it shows a node or
   pod IP, stop and fix that first.

4. **Protect one low-risk route.** Add the filter to its rules and add its
   namespace to `referencegrant.yml`:

   ```yaml
   spec:
     rules:
       - filters:
           - type: ExternalAuth
             externalAuth:
               protocol: GRPC
               backendRef:
                 name: crowdsec-envoy-bouncer
                 namespace: crowdsec
                 port: 8080
               forwardBody:
                 maxSize: 65536   # lets AppSec inspect POST bodies
         backendRefs:
           - name: my-app
             port: 80
   ```

   Confirm the field names your CRDs accept first:
   `kubectl explain httproute.spec.rules.filters.externalAuth --recursive`.
   Then `kubectl describe httproute <name>` should show `Accepted` and
   `ResolvedRefs` as `True`.

5. **Test enforcement:**

   ```sh
   kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli decisions add --ip <your-public-ip> --duration 5m
   # from that IP: expect a 403 ban page within ~10s
   kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli decisions delete --ip <your-public-ip>
   ```

   Also scale the bouncer to 0 briefly and see whether the route fails open
   or closed, so you know before it happens for real.

6. Roll the filter out to the remaining routes.

## Things that may need adjusting

- **`container_runtime`**: set to `containerd`; change to `docker` if your nodes use Docker.
- **Persistence**: the CrowdSec chart stores LAPI data on a PersistentVolume
  by default, which needs a default StorageClass. Without one the LAPI pod stays Pending.
- **Client IP**: if bans don't match in step 5, set `logLevel: debug` on the
  bouncer, look at which IP it evaluates, and fill in `trustedProxies`.
- **CAPTCHA** is off. Turning it on needs a reCAPTCHA/Turnstile key, a
  signing key, and an HTTPRoute exposing the bouncer's :8081 at a public
  `callbackURL` (the chart has an `httproute.*` block for that).
- **Image architecture**: CrowdSec's guide says the bouncer image is amd64;
  check before scheduling it on arm64 nodes.
