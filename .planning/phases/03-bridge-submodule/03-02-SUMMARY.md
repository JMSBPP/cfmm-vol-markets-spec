---
phase: 03-bridge-submodule
plan: 02
subsystem: bridge
tags: [hevm, foundry, ffi, haskell, tickmath]
requires:
  - phase: 03-bridge-submodule
    provides: "Pinned bridge transport probe and profile.hevm"
provides:
  - "Private hevm-adapter + hevm-tickmath-peer executing compiled TickMath bytecode"
  - "Live profile-gated HevmTickMathHarness via hevm.call"
  - "Bounded scripts/hevm-tickmath-relay.sh with GREEN min-tick HevmDiffTest"
affects: [03-03, ci, sqrtgrid]
tech-stack:
  added: [hevm-0.58.0, hevm-tickmath-peer]
  patterns:
    - "JSON string results avoid Foundry ffi hex-decoding digit-only stdout"
    - "HEVM_LIVE + RELAY_SOCK readiness gate (FOUNDRY_PROFILE alone is not cheatcode-visible reliably)"
    - "Side B uses Seaport try/catch assertPass for stateless success"
key-files:
  created:
    - src/HevmTickMathAdapter.hs
    - app/HevmTickMathPeer/Main.hs
    - scripts/hevm-tickmath-relay.sh
  modified:
    - package.yaml
    - stack.yaml
    - cfmm-vol-markets-spec.cabal
    - evm/src/HevmTickMathHarness.sol
    - evm/test/diff/TickMath.Hevm.diff.t.sol
key-decisions:
  - "Adapter executes Forge TickMathHarness runtime in Hackage HEVM; SqrtGrid is boundary types only."
  - "Peer returns quoted JSON string \"4295128739\" for min-tick."
  - "Runner isolates green vs readiness tests to avoid vm.setEnv races."
requirements-completed: [BRIDGE-01, BRIDGE-02]
---

# Plan 03-02 Summary

## Outcome

Live minimum-tick differential is GREEN through pinned `hevm.call` → relayd → local EVM-backed peer. Public Haskell library remains HEVM-free.

## Verification

- `stack exec -- hevm-tickmath-peer --probe -887272 --artifact evm/out/TickMathHarness.sol/TickMathHarness.json` → `4295128739`
- `bash scripts/hevm-tickmath-relay.sh` → probe `"4295128739"`, `test_getSqrtPriceAtTick_isValidMinTick` PASS, readiness PASS in isolated process
- No `src/EVM.hs`; `hevm` only on private `hevm-adapter` component

## Commits

- `187244c` / `bab2a49` / `781b55f` — adapter peer + RED readiness scaffolding
- `8db32af` — initial live harness + runner
- `7303bc4` — quoted JSON / HEVM_LIVE / Side B assertPass fixes
