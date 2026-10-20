# kind: the whole project on one machine

Terraform for a local [kind](https://kind.sigs.k8s.io) cluster that runs the same K1 deployment
as EKS, with no AWS account and no cost. As with `infra/eks`, Terraform creates only the
cluster; everything inside it is a Kustomize manifest applied with `kubectl`.

## What changes from EKS

| EKS Auto Mode | kind |
| --- | --- |
| VPC, NAT gateway, IAM roles, access entries | Not needed: one Docker container per node |
| ECR repository | No registry: `kind load docker-image` copies the local build into the node |
| ALB with ACM certificate on `lmgate.nairvarun.com` | ingress-nginx on `http://localhost` (host ports 80/443, bound to 127.0.0.1) |
| `auto-ebs-gp3` StorageClass | kind's built-in `standard` (local-path), already the default |
| VPC CNI network policy controller | kindnet, which enforces NetworkPolicy out of the box |
| amd64 nodes | Your machine's architecture; build the image without `--platform` |

| Path | Contents |
| --- | --- |
| `infra/kind/` | The cluster: one control-plane node labelled `ingress-ready=true` with ports 80/443 mapped to the host, plus optional workers |
| `deploy/k8s/cluster/kind/` | Baseline: ingress-nginx (kind flavour, pinned to v1.15.1) |
| `deploy/k8s/overlays/kind/` | The `k1` overlay with `ingressClassName: nginx` and the local `llm-gateway:dev` image |

## Prerequisites

Docker (or Podman with kind's Docker-compatible socket), Terraform >= 1.10, `kubectl`, and the
`kind` CLI for loading the image. The Terraform provider embeds kind itself, so the cluster can
be created without the CLI.

Ports 80 and 443 on 127.0.0.1 must be free. If they are not, set `http_port` and `https_port`
in `terraform.tfvars` (see `terraform.tfvars.example`) and use that port in the URLs below.

## Deploy

```bash
# 1. Cluster (about a minute); kind switches kubectl to the kind-llm-gateway context
cd infra/kind
terraform init
terraform apply
cd ../..

# 2. Cluster baseline: the ingress controller
kubectl apply -k deploy/k8s/cluster/kind
kubectl -n ingress-nginx wait --for=condition=Available deploy/ingress-nginx-controller --timeout=180s

# 3. Image: build locally and copy it into the node
docker build -t llm-gateway:dev .
kind load docker-image llm-gateway:dev --name llm-gateway

# 4. Secrets and the gateway
cp deploy/k8s/base/secrets.env.example deploy/k8s/base/secrets.env   # fill in; git-ignored
kubectl apply -k deploy/k8s/overlays/kind
kubectl -n llm-gateway rollout status deploy/gateway
curl -s http://localhost/v1/models -H "Authorization: Bearer <a gw- key>"
```

Create a key through a port-forward, since `/admin` is not routed by the Ingress:

```bash
kubectl -n llm-gateway port-forward deploy/gateway 8080 &
curl -s -X POST localhost:8080/admin/keys -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H 'content-type: application/json' -d '{"name": "me"}'
```

After a code change, rebuild with a new tag (or the same one), `kind load` it again, and
`kubectl -n llm-gateway rollout restart deploy/gateway`.

## Tear down

```bash
terraform -chdir=infra/kind destroy   # deletes the node containers, and the PVC's data with them
```

## Notes

- **Linux hosts need cgroup v2.** Kubernetes 1.35's kubelet refuses to start on cgroup v1, so
  `terraform apply` fails at `kubeadm init` there. Docker Desktop and current distributions
  use v2 already.
- **Plain HTTP.** The gateway is only on localhost, so there is no certificate. Set
  `listen_address = "0.0.0.0"` only if you mean to expose it to your network, and then add TLS.
- **ingress-nginx is retired upstream** (no releases after v1.15). That is acceptable for a
  local cluster; the base Ingress's streaming annotations (`proxy-read-timeout`,
  `proxy-buffering`) are written for it.
- **Provider keys still apply.** The gateway refuses to start if a key referenced in
  `config.yaml` is missing, so `secrets.env` needs real (or at least non-empty) values.
- **Prometheus** is not installed, as on EKS; the pod carries scrape annotations for when one is.
