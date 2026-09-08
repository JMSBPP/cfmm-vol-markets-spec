#!/usr/bin/env bash
# Build and run the live relay -> local HEVM TickMath peer -> Forge differential.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE_ROOT="$ROOT/evm/lib/evm-spec-bridge"
SOCK="${RELAY_SOCK:-${TMPDIR:-/tmp}/cfmm-hevm-tickmath-$$.sock}"
ARTIFACT="$ROOT/evm/out/TickMathHarness.sol/TickMathHarness.json"
export RELAY_SOCK="$SOCK"

cleanup() {
  if [[ -n "${PEER_PID:-}" ]]; then
    kill "$PEER_PID" 2>/dev/null || true
    wait "$PEER_PID" 2>/dev/null || true
  fi
  if [[ -n "${RELAYD_PID:-}" ]]; then
    kill "$RELAYD_PID" 2>/dev/null || true
    wait "$RELAYD_PID" 2>/dev/null || true
  fi
  rm -f "$SOCK" "${SOCK}.ctl"
}
trap cleanup EXIT

cd "$ROOT"
forge build --root evm
stack --stack-yaml "$BRIDGE_ROOT/stack.yaml" build \
  evm-spec-bridge-relay:exe:relay \
  evm-spec-bridge-relay:exe:relayd \
  --fast
stack build cfmm-vol-markets-spec:exe:hevm-tickmath-peer --pedantic

BRIDGE_BIN="$(stack --stack-yaml "$BRIDGE_ROOT/stack.yaml" path --local-install-root)/bin"
LOCAL_BIN="$(stack path --local-install-root)/bin"
export PATH="$BRIDGE_BIN:$LOCAL_BIN:$PATH"

rm -f "$SOCK" "${SOCK}.ctl"
relayd --sock "$SOCK" &
RELAYD_PID=$!

control_ready=0
for _ in $(seq 1 50); do
  if [[ -S "${SOCK}.ctl" ]]; then
    control_ready=1
    break
  fi
  sleep 0.1
done
if [[ "$control_ready" -ne 1 ]]; then
  echo "ERROR: relayd control socket not ready at ${SOCK}.ctl" >&2
  exit 1
fi

hevm-tickmath-peer --sock "$SOCK" --artifact "$ARTIFACT" &
PEER_PID=$!

peer_ready=0
for _ in $(seq 1 50); do
  if response="$(relay send getSqrtPriceAtTick '[-887272]' 2>/dev/null)" \
    && [[ "$response" = "4295128739" ]]; then
    peer_ready=1
    break
  fi
  sleep 0.1
done
if [[ "$peer_ready" -ne 1 ]]; then
  echo "ERROR: HEVM TickMath peer did not return 4295128739" >&2
  exit 1
fi
printf 'HEVM TickMath relay probe: %s\n' "$response"

FOUNDRY_PROFILE=hevm forge test \
  --root evm \
  --match-contract HevmDiffTest \
  -vv
