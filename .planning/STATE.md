# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-08)

**Core value:** Plots and tests stay green, and the numeric core is bit-identical to the EVM — Forge TickMath differential + `hevm.call` is the oracle.

**Current focus:** Phase 1 — Forge `evm/` + v3-core (awaiting discuss/plan)

## Current Position

| Field | Value |
|-------|--------|
| Milestone | v1 — HEVM Bit-Identical Vol-Markets Twin |
| Phase | 1 of 8 (not started) |
| Mode | Vertical MVP |
| Granularity | Fine |
| Workflow | Interactive; research on; plan_check off; verifier on |

## Decisions Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Local GSD in scratchpad | Separate from parent Shreve track | 2026-09-08 |
| Vertical MVP | End-to-end slices; TickMath TDD first | 2026-09-08 |
| `evm-spec-bridge` as submodule | `hevm.call`; failures → issue + user notify | 2026-09-08 |
| Hybrid replacement | Forge+HEVM oracle, then Haskell rewrite | 2026-09-08 |

## Blockers

None yet.

## Next Actions

1. Approve roadmap (or adjust phases)
2. `$gsd-discuss-phase 1` — gather context for Forge `evm/` scaffold
3. `$gsd-plan-phase 1` — then execute

## Notes

- Research: `.planning/research/` especially `HEVM-FORGE-TICKMATH.md`
- research-store key: see `.planning/research/INDEX.md`

---
*State initialized: 2026-09-08*
