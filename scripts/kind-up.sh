#!/usr/bin/env bash
# Deploy the gateway into a local kind cluster: create the cluster if needed, build and load the
# image, apply the kind overlay, and wait for the rollout. Safe to re-run after a code change.
# Needs docker, kind and kubectl, and deploy/k8s/base/secrets.env (copy secrets.env.example).
set -euo pipefail
cd "$(dirname "$0")/.."

CLUSTER=llm-gateway
IMAGE=llm-gateway:dev

for tool in docker kind kubectl; do
  command -v "$tool" >/dev/null || { echo "$tool is not installed" >&2; exit 1; }
done
if [[ ! -f deploy/k8s/base/secrets.env ]]; then
  echo "deploy/k8s/base/secrets.env is missing: copy secrets.env.example and fill it in" >&2
  exit 1
fi

if ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --config deploy/kind/cluster.yaml
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null

docker build -t "$IMAGE" .
kind load docker-image "$IMAGE" --name "$CLUSTER"

# The tag never changes, so a re-run must restart the pod to pick up the newly loaded image.
existed=$(kubectl -n llm-gateway get deploy/gateway -o name 2>/dev/null || true)
kubectl apply -k deploy/k8s/overlays/kind
if [[ -n "$existed" ]]; then
  kubectl -n llm-gateway rollout restart deploy/gateway
fi
kubectl -n llm-gateway rollout status deploy/gateway --timeout=180s

echo "Gateway is up at http://localhost:8080 (try: curl localhost:8080/readyz)"
