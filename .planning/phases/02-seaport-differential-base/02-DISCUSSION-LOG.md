# Phase 2: Seaport differential base - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-08
**Phase:** 2-Seaport differential base
**Areas discussed:** DifferentialTest source, DiffTestBase/HevmDiffTest shape, smoke suite, layout/remappings, CI

---

## Gray area selection

**User's choice:** `all` (areas 1–5)

---

## Area 1 — DifferentialTest source

| Q | Options | Selected |
|---|---------|----------|
| How obtain DifferentialTest | 1 forge install Seaport / 2 vendor only / 3 you decide | **1** |
| Seaport pin | 1 `@1.6` / 2 vol-markets commit / 3 you decide | **1** |
| Remapping | 1 `@seaport/=lib/seaport/test/foundry/` / 2 shorter / 3 you decide | **1** |
| forge-std | 1 dedicated top-level install / 2 reuse nested / 3 you decide | **1** |

**Checkpoint:** Next area (not more on source)

---

## Area 2 — DiffTestBase / HevmDiffTest shape

| Q | Options | Selected |
|---|---------|----------|
| Base shape | 1 thin DiffTestBase / 2 mirror TestBase / 3 you decide | *(superseded by freeform)* |
| Architecture (freeform) | Uniswap TickMath tests as client; HevmDiffTest; same test names; Side B harness = hevm.call→Haskell | **locked** |
| Phase 2 deliverable | 1 base-only / 2 skeleton HevmDiffTest now / 3 you decide | **2** |
| TickMathTest entry | 1 inherit via v4-core remap / 2 vendor copy / 3 you decide | **1** |
| HEVM stub | 1 revert RED / 2 skip green / 3 you decide | **1** |

**Notes:** Clarified upstream `TickMathTest` (harness) vs `TickMathTestTest` (suite). Checkpoint → next.

---

## Area 3 — Smoke / skeleton

| Q | Options | Selected |
|---|---------|----------|
| First test_* | 1 `test_getSqrtPriceAtTick_isValidMinTick` / 2 MIN_TICK invariant / 3 you decide | **1** |
| Filename | 1 `TickMath.Hevm.diff.t.sol` / 2 `TickMath.diff.t.sol` / 3 you decide | **1** |
| RED treatment | 1 compile+intentional fail / 2 vm.skip / 3 you decide | **1** |

**Checkpoint:** Next area

---

## Area 4 — Layout / remappings

| Q | Options | Selected |
|---|---------|----------|
| Paths | 1 test/diff base+suite, harness src or test/harness / 2 all under test/diff / 3 you decide | **1** |
| Uniswap imports | 1 remaps keep evm/src ours / 2 second FOUNDRY profile / 3 you decide | **1** |
| Harness path | 1 `evm/src/HevmTickMathHarness.sol` / 2 test/harness / 3 you decide | **1** |

**Checkpoint:** Next area

---

## Area 5 — CI

| Q | Options | Selected |
|---|---------|----------|
| Gate policy | 1 build green + RED documented/asserted / 2 exclude RED from required test / 3 you decide | **1** |
| Prove RED | 1 CI assert non-zero forge test / 2 docs-only / 3 you decide | **1** |
| Seaport pins on CI | 1 recursive + pin asserts / 2 build only / 3 you decide | **1** |

---

## Done

**User's choice:** Ready for context (write CONTEXT.md)

## the agent's Discretion

- forge-std exact tag; DiffTestBase naming; remapping alias details; match-contract filter string; stub error string

## Deferred Ideas

- Bridge / hevm.call → Phase 3; full corpus → Phase 4; SqrtGrid → 5–6; CI-green HevmDiffTest after bridge
