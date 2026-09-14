# Phase 3: Bridge submodule - Context

**Gathered:** 2026-09-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Consume **`evm-spec-bridge`** so `hevm.call` is importable from the Forge tree, document relay / `FOUNDRY_PROFILE=hevm` + BRIDGE-03, and replace the Phase 2 harness stub with a **live dual-path `hevm.call`** for the min-tick vector — backed by a **thin Haskell adapter in this package** that depends on Hackage **`hevm`** (`module EVM` / `EVM.hs`), not a greenfield `EVM.hs`.

**Delivers (BRIDGE-01..03 + expanded harness wire-up):**
- `evm-spec-bridge` as a git submodule (`feat/2-hevm-call-stdcheats` / agreed pin)
- Remaps / imports so Solidity can call `hevm.call(method, paramsJson)`
- Docs: relay + `FOUNDRY_PROFILE=hevm` (or equivalent); `evm/` README references BRIDGE-03 / `AGENTS.md` §7
- Cabal/`package.yaml`: **`hevm` build-depends**; thin `src/` adapter that imports **`EVM`** and exposes **one** TickMath entry (`getSqrtPriceAtTick`) for HEVM/`hevm.call`
- `HevmTickMathHarness`: live `hevm.call` when profile/env says HEVM is up; distinct loud fail when down
- **CI requires GREEN** on the min-tick differential with relay + HEVM up

**Does not deliver:** full TickMath corpus (Phase 4); full SqrtGrid bit-identical port / mulDiv (Phases 5–7); inventing a local `src/EVM.hs`.

</domain>

<decisions>
## Implementation Decisions

### Gray-area focus
- **D-01:** Discussed **harness wire-up** only. Submodule path/pin layout and solc/`^0.8.34` remapping strategy were **not** discussed — planner/implementer discretion (see Discretion + Deferred scout note).

### Harness / `hevm.call`
- **D-02:** Replace Phase 2 stub with **live `hevm.call`** (encode TickMath method/params) — GREEN only when relay/HEVM is up.
- **D-03:** **Dual path:** when `FOUNDRY_PROFILE=hevm` (or equivalent env) is set and the path is live, call through; otherwise **explicit revert** with a distinct “relay/profile down” message (not silent skip, not the old `"hevm.call not wired"` forever).
- **D-04:** First live vector remains **`test_getSqrtPriceAtTick_isValidMinTick`** / harness `getSqrtPriceAtTick` only.

### Haskell / HEVM surface (prerequisite for queryable Side B)
- **D-05:** **`EVM.hs` is not authored here** — use **`module EVM` from the Hackage `hevm` Cabal package** (verified locally as `hevm-0.58.0/src/EVM.hs`).
- **D-06:** Phase 3 **declares `hevm` as a dependency** and adds a **thin adapter** so one TickMath method is callable via the bridge/`hevm.call`.
- **D-07:** Thin adapter **lives in this package** (`src/` module importing `EVM`); this package owns the HEVM-facing TickMath/SqrtGrid entry the relay hits.
- **D-08:** Surface is **one method only** — `getSqrtPriceAtTick` (enough for min-tick GREEN); remaining TickMath API later (Phase 4+).

### CI
- **D-09:** Phase 3 CI **requires GREEN**: start relay + HEVM and expect the min-tick `HevmDiffTest` vector to pass (replaces Phase 2’s intentional-RED/`hevm.call not wired` gate for this suite once wired).

### Already locked (from REQUIREMENTS / prior phases — do not reopen)
- Submodule repo/branch: **`JMSBPP/evm-spec-bridge`**, **`feat/2-hevm-call-stdcheats`**
- Do not reinvent cheats/relay; BRIDGE-03 → issue on bridge repo + notify user (`AGENTS.md` §7)
- Side A = v4-core TickMath; Side B = harness → `hevm.call` → Haskell
- Research tip when captured: `aad230528f93be04a00d0209f10eaa3084d84de5` (confirm at plan/execute time)

### the agent's Discretion
- Exact submodule filesystem path (`evm/lib/…` vs root `lib/…`) and whether to pin tip SHA vs floating branch tip at add time
- How to reconcile bridge `Hevm.sol` `pragma ^0.8.34` with current `evm/` **solc 0.8.28** (bump vs profile/isolation)
- Exact Cabal/`package.yaml` / Stack wiring for `hevm` (version bounds, flags, extra-deps)
- Thin adapter module name, method JSON shape, and how SqrtGrid is referenced from the adapter without a full bit-id rewrite
- Exact dual-path gate (`FOUNDRY_PROFILE=hevm` vs env var vs both) and distinct revert string when down
- CI job shape for bringing up relayd/HEVM (services, scripts, timeouts) — must still satisfy D-09

</decisions>

<specifics>
## Specific Ideas

- User: live harness (1) **and** dual path (3), with prerequisite that `SqrtGrid` become queryable under `hevm.call` via **`EVM` from the hevm Cabal dependency** — not a new file under `src/`.
- User chose adapter ownership in **this package** and **one-method** thinness for Phase 3 GREEN.
- User chose **CI must go GREEN** with relay+HEVM (not keep RED default / build-only).

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project / phase
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md` — BRIDGE-01..03; TICK-03 seam note
- `.planning/ROADMAP.md` — Phase 3 section
- `.planning/STATE.md`
- `.planning/phases/02-seaport-differential-base/02-CONTEXT.md` — harness stub, HevmDiffTest, D-09 first vector
- `.planning/phases/02-seaport-differential-base/02-VERIFICATION.md` — Phase 2 RED contract being replaced

### Research / bridge
- `.planning/research/HEVM-FORGE-TICKMATH.md` — submodule URL, branch, tip SHA, `Hevm.sol`, BRIDGE-03 protocol
- `AGENTS.md` §7 — submodule failure protocol
- Local bridge worktree: `/home/jmsbpp/apps/evm_spec_rpc/.worktrees/hevm-call-stdcheats`
- Bridge design: `/home/jmsbpp/apps/evm_spec_rpc/docs/superpowers/specs/2026-09-08-foundry-hevm-relay-design.md`

### Haskell
- Hackage package **`hevm`** — `src/EVM.hs` (`module EVM`); do not invent a twin
- `package.yaml` / `cfmm-vol-markets-spec.cabal` — currently plot-free public lib; add `hevm` carefully
- `src/SqrtGrid.hs` — numeric twin; Phase 3 exposes one query path, not full bit-id rewrite

### Local Forge seam
- `evm/src/HevmTickMathHarness.sol` — body to replace
- `evm/test/diff/TickMath.Hevm.diff.t.sol` — min-tick skeleton
- `evm/foundry.toml`, `.github/workflows/ci.yml`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 2 `HevmTickMathHarness` + `HevmDiffTest` / `DiffTestBase` — only Side B body and CI gate need updating
- Bridge `solidity/src/Hevm.sol` — `hevm.call(method, paramsJson)` via ffi → relay
- Hackage `hevm` `EVM` module — already exists; depend, don’t fork

### Established Patterns
- Seaport differential: same `test_*` names; Side A Solidity TickMath; Side B HEVM/Haskell
- BRIDGE-03: issue on bridge + notify user; no silent local patches around bridge bugs

### Integration Points
- Forge harness → `hevm.call` → relay → HEVM peer → thin `src/` adapter → `getSqrtPriceAtTick`
- CI must provision relay + HEVM for GREEN min-tick

</code_context>

<deferred>
## Deferred Ideas

- **Submodule path + pin layout** — gray area 1 not selected; still required work, agent discretion
- **Solc / remapping for `^0.8.34`** — gray area 2 not selected; scout note remains; agent discretion
- Full Uniswap TickMath corpus → **Phase 4**
- Broader `hevm.call` seam / oracle maturity → **Phase 5** (roadmap); Phase 3 still wires the first live path
- Bit-identical SqrtGrid TickMath + `mulDiv` → **Phases 6–7**
- Full TickMath API mirror on the Haskell adapter → later phases

</deferred>

---

*Phase: 03-bridge-submodule*
*Context gathered: 2026-09-08*
