#!/usr/bin/env bash
# End-to-end checks for the cloudflared deployment on kind.
#
# Default (local only, nothing is exposed to the internet):
#   1. the cloudflared manifests are admitted under the "restricted" Pod
#      Security Standard (server-side dry run)
#   2. the cluster exposes nothing itself: no LoadBalancer or NodePort
#   3. NetworkPolicy: a pod with cloudflared's labels reaches the exposed
#      namespace but not an unlabelled one, and cannot reach the API server
#
# Opt-in, E2E_PUBLIC_TUNNEL=1 (makes the demo origin PUBLIC while it runs):
#   4. a Cloudflare quick tunnel (no account needed) registers, and a
#      request to its trycloudflare.com URL reaches the origin through
#      Cloudflare (cf-ray header present). The tunnel is deleted afterwards.
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck disable=SC1091
source versions.env

CLUSTER=${CLUSTER:-edge-e2e}
PUBLIC=${E2E_PUBLIC_TUNNEL:-0}
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*" >&2; exit 1; }

if ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --name "$CLUSTER" --image "$KIND_NODE_IMAGE" --config tests/e2e/kind.yaml --wait 120s
fi
kubectl config use-context "kind-$CLUSTER" >/dev/null

kubectl apply -f kubernetes/demo/app.yaml >/dev/null
kubectl -n app rollout status deploy/web --timeout=120s >/dev/null
kubectl -n private rollout status deploy/web --timeout=120s >/dev/null

# 1. Admission under restricted Pod Security
kubectl apply -f kubernetes/cloudflared/base/namespace.yaml >/dev/null
if ! out=$(kubectl apply -k kubernetes/cloudflared/base --dry-run=server 2>&1); then
  fail "cloudflared manifests rejected: $out"
fi
grep -qi "warning" <<<"$out" && fail "admission warnings: $out"
pass "cloudflared manifests admitted under restricted Pod Security"
kubectl apply -f kubernetes/cloudflared/base/networkpolicy.yaml -n cloudflared >/dev/null

# 2. Nothing exposed by the cluster itself
exposed=$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type!="ClusterIP")]}{.metadata.namespace}/{.metadata.name} {.spec.type}{"\n"}{end}')
[[ -z "$exposed" ]] || fail "services exposed outside the cluster: $exposed"
pass "no LoadBalancer or NodePort services"

# 3. NetworkPolicy isolation, using a probe pod that matches cloudflared's policy
kubectl -n cloudflared delete pod np-probe --ignore-not-found --wait=true >/dev/null
kubectl -n cloudflared run np-probe --image=curlimages/curl:8.17.0 --labels=app=cloudflared --restart=Never \
  --overrides='{"spec":{"automountServiceAccountToken":false,"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"np-probe","image":"curlimages/curl:8.17.0","command":["sleep","300"],"securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}' >/dev/null
kubectl -n cloudflared wait --for=condition=Ready pod/np-probe --timeout=90s >/dev/null
probe() { kubectl -n cloudflared exec np-probe -- curl -sk -o /dev/null -w '%{http_code}' --max-time 5 "$1" 2>/dev/null || true; }

# Retry the positive check briefly: right after a rollout the Service can
# still point at a terminating pod.
reached=""
for _ in $(seq 1 10); do
  [[ "$(probe http://web.app.svc.cluster.local)" == "200" ]] && { reached=1; break; }
  sleep 2
done
[[ -n "$reached" ]] || fail "cloudflared cannot reach the exposed namespace"
pass "cloudflared can reach namespaces labelled edge.cloudflare.com/exposed"

code=$(probe http://web.private.svc.cluster.local)
[[ "$code" != "200" ]] || fail "cloudflared reached an unlabelled namespace"
pass "cloudflared cannot reach unlabelled namespaces (got '${code:-timeout}')"

code=$(probe https://kubernetes.default.svc.cluster.local/version)
[[ "$code" != "200" && "$code" != "401" && "$code" != "403" ]] || fail "cloudflared reached the API server ($code)"
pass "cloudflared cannot reach the Kubernetes API server (got '${code:-timeout}')"
kubectl -n cloudflared delete pod np-probe --wait=false >/dev/null

if [[ "$PUBLIC" != "1" ]]; then
  echo "local e2e checks passed (public quick-tunnel check skipped; set E2E_PUBLIC_TUNNEL=1 to run it)"
  exit 0
fi

# 4. Opt-in: real Cloudflare edge via a quick tunnel
cleanup() { kubectl delete -k kubernetes/cloudflared/overlays/quick-tunnel --ignore-not-found >/dev/null 2>&1 || true; }
trap cleanup EXIT
kubectl apply -k kubernetes/cloudflared/overlays/quick-tunnel >/dev/null
kubectl -n cloudflared rollout status deploy/cloudflared --timeout=180s >/dev/null
url=""
for _ in $(seq 1 30); do
  url=$(kubectl -n cloudflared logs deploy/cloudflared 2>/dev/null | grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' | head -1 || true)
  [[ -n "$url" ]] && break
  sleep 2
done
[[ -n "$url" ]] || fail "no quick tunnel URL in cloudflared logs"
pass "quick tunnel registered"

ok=""
for _ in $(seq 1 30); do
  if resp=$(curl -sS -D - --max-time 10 "$url/" 2>/dev/null) && grep -q "demo origin" <<<"$resp"; then
    ok=1; break
  fi
  sleep 3
done
[[ -n "$ok" ]] || fail "origin not reachable through the quick tunnel"
grep -qi '^cf-ray:' <<<"$resp" || fail "response did not come through Cloudflare (no cf-ray header)"
pass "request reached the origin through Cloudflare's edge"
echo "all e2e checks passed (tunnel removed on exit)"
