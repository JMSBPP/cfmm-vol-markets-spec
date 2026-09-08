---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 2
current_phase_name: Seaport differential base
status: Phase 2 complete — ready for verification
stopped_at: Completed 02-02-PLAN.md
last_updated: "2026-09-08T16:27:05.447Z"
progress:
  total_phases: 8
  completed_phases: 2
  total_plans: 3
  completed_plans: 3
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-08)

**Core value:** Plots and tests stay green, and the numeric core is bit-identical to the EVM — Forge TickMath differential + `hevm.call` is the oracle.

**Current focus:** Phase 2 — Seaport differential base is complete and ready for verification.

## Current Position

| Field | Value |
|-------|--------|
| Milestone | v1 — HEVM Bit-Identical Vol-Markets Twin |
| Phase | 2 of 8 (Seaport differential base) |
| Current Plan | 2 |
| Total Plans in Phase | 2 |
| Plans | 2/2 complete (`02-01-SUMMARY.md`, `02-02-SUMMARY.md`) |
| Status | Phase complete — ready for verification |
| Mode | Vertical MVP + Walking Skeleton |
| Granularity | Fine |
| Workflow | Interactive; research on; plan_check off; verifier on |

## Decisions Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Local GSD in scratchpad | Separate from parent Shreve track | 2026-09-08 |
| Vertical MVP | End-to-end slices; TickMath TDD first | 2026-09-08 |
| `evm-spec-bridge` as submodule | `hevm.call`; failures → issue + user notify | 2026-09-08 |
| Hybrid replacement | Forge+HEVM oracle, then Haskell rewrite | 2026-09-08 |
| Phase 1 oracle = v4-core@v4.0.0 | CONTEXT D-01/D-02; no Uniswap `@0.8` tag | 2026-09-08 |
| Phase 2 HevmDiffTest skeleton | Uniswap TickMath client; HEVM stub RED until bridge | 2026-09-08 |

## Blockers

None yet.

## Next Actions

1. `$gsd-verify-work 2` — verify the Phase 2 dependency and intentional-RED CI contract
2. `$gsd-discuss-phase 3` — bridge / `hevm.call`

## Notes

- Phase 1 artifacts: `.planning/phases/01-forge-evm-v3-core/`
- Research: `.planning/research/` especially `HEVM-FORGE-TICKMATH.md`

---

## Session

**Last session:** 2026-09-08T16:27:05.439Z
**Stopped at:** Completed 02-02-PLAN.md
**Resume file:** None

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01-forge-evm-v3-core P01 | 3 min | 2 tasks | 10 files |
| Phase 02 P01 | 3 min | 2 tasks | 10 files |
| Phase 02-seaport-differential-base P02 | 4 min | 2 tasks | 3 files |

## Decisions

- [Phase 01-forge-evm-v3-core]: Pinned Uniswap/v4-core@v4.0.0 at e50237c43811bd9b526eff40f26772152a42daba as the TickMath oracle. — D-01/D-02 require a fixed official v4 source for reproducible EVM bit-identity work.
- [Phase 02-seaport-differential-base]: Pinned Seaport 1.6 and dedicated forge-std v1.16.1; preserve Side B's raw HEVM revert so the RED gate proves the adapter boundary. — Exact pins provide reproducible builds, while preserving the marker prevents a generic differential failure from satisfying the Phase 2 RED contract.
- [Phase 02-seaport-differential-base]: CI requires both a non-zero HevmDiffTest exit and the hevm.call not wired marker; unrelated failures and a silently green seam are rejected. — D-16 and T-2-03/T-2-04 require a cause-specific Phase 2 RED gate.
