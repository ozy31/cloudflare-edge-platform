#!/usr/bin/env bash
# Create or update the cloudflared token Secret from stdin, so the token is
# never written to disk or shown in shell history:
#   terraform -chdir=terraform output -raw tunnel_token | hack/tunnel-secret.sh
set -euo pipefail
ns=${NAMESPACE:-cloudflared}
token=$(cat)
[[ -n "$token" ]] || { echo "no token on stdin" >&2; exit 1; }
kubectl create secret generic cloudflared-token -n "$ns" \
  --from-literal=token="$token" --dry-run=client -o yaml | kubectl apply -f -
