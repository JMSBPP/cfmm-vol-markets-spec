---
phase: 03-bridge-submodule
plan: 03
subsystem: bridge
tags: [ci, docs, hevm]
requires:
  - phase: 03-bridge-submodule
    provides: "Live min-tick relay runner GREEN"
provides:
  - "Operator README with BRIDGE-02/03"
  - "CI hevm-diff job requiring scripts/hevm-tickmath-relay.sh"
  - "Nyquist validation map closed"
affects: [merge-gate]
tech-stack:
  added: []
  patterns:
    - "CI GREEN replaces Phase 2 intentional-RED HevmDiffTest assert"
key-files:
  created: []
  modified:
    - evm/README.md
    - .github/workflows/ci.yml
    - .planning/phases/03-bridge-submodule/03-VALIDATION.md
key-decisions:
  - "Required hevm-diff job invokes the bounded real-peer runner only."
requirements-completed: [BRIDGE-02, BRIDGE-03]
---

# Plan 03-03 Summary

## Outcome

Documentation and CI enforce the live relay path. Phase 2 expected-RED gate removed.

## Verification

- README documents `FOUNDRY_PROFILE=hevm`, `RELAY_SOCK`/`HEVM_LIVE`, bridge SHA, both smokes, BRIDGE-03 → AGENTS §7
- CI asserts bridge pin; `hevm-diff` runs `bash scripts/hevm-tickmath-relay.sh`; no `intentionally RED` step
- VALIDATION.md marked complete / nyquist compliant
