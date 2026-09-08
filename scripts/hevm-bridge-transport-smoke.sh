#!/usr/bin/env bash
# Run the consumer-owned hevm.call transport probe against the pinned bridge stack.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE_ROOT="$ROOT/evm/lib/evm-spec-bridge"

if [[ -n "${RELAY_SOCK:-}" ]]; then
  SOCK="$RELAY_SOCK"
  RUN_DIR=""
else
  RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cfmm-hevm-transport.XXXXXX")"
  SOCK="$RUN_DIR/relay.sock"
fi
export RELAY_SOCK="$SOCK"

cleanup() {
  if [[ -n "${ECHO_PID:-}" ]]; then
    kill "$ECHO_PID" 2>/dev/null || true
    wait "$ECHO_PID" 2>/dev/null || true
  fi
  if [[ -n "${RELAYD_PID:-}" ]]; then
    kill "$RELAYD_PID" 2>/dev/null || true
    wait "$RELAYD_PID" 2>/dev/null || true
  fi
  rm -f "$SOCK" "${SOCK}.ctl"
  if [[ -n "$RUN_DIR" ]]; then
    rmdir "$RUN_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT

stack --stack-yaml "$BRIDGE_ROOT/stack.yaml" build \
  evm-spec-bridge-relay:exe:relay \
  evm-spec-bridge-relay:exe:relayd \
  evm-spec-bridge-relay:exe:fake-hevm-echo \
  --fast
BIN="$(stack --stack-yaml "$BRIDGE_ROOT/stack.yaml" path --local-install-root)/bin"
export PATH="$BIN:$PATH"

rm -f "$SOCK" "${SOCK}.ctl"
"$BIN/relayd" --sock "$SOCK" &
RELAYD_PID=$!

ready=0
for _ in $(seq 1 50); do
  if [[ -S "${SOCK}.ctl" ]]; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then
  echo "ERROR: relayd control socket not ready at ${SOCK}.ctl" >&2
  exit 1
fi

"$BIN/fake-hevm-echo" --sock "$SOCK" &
ECHO_PID=$!

ready=0
for _ in $(seq 1 50); do
  if result="$("$BIN/relay" send echo '[1]' 2>/dev/null)" && [[ "$result" == "[1]" ]]; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then
  echo "ERROR: bridge echo peer not ready at $SOCK" >&2
  exit 1
fi

FOUNDRY_PROFILE=hevm forge test \
  --root "$ROOT/evm" \
  --match-path test/bridge/HevmCallProbe.t.sol \
  -vv
