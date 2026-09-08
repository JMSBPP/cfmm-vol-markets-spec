# Phase 1: Forge `evm/` + v3-core - Context

**Gathered:** 2026-09-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Scaffold a Foundry project at `evm/` and make Uniswap **v4** `TickMath` importable so later phases can write Seaport-style differentials. This phase is **scaffold + dependency pin only** — not the implementation-driving differential test.

**Delivers:** `forge build` green under `evm/`; `TickMath` importable from pinned `Uniswap/v4-core@v4.0.0`; pin recorded in remappings/lock/README note.

**Does not deliver:** Seaport `DifferentialTest` base, TickMath↔SqrtGrid `.diff.t.sol`, bridge submodule, or Haskell `SqrtGrid` changes.

</domain>

<decisions>
## Implementation Decisions

### TickMath oracle source (was `v3-core@0.8`)
- **D-01:** Use **Uniswap v4 `TickMath`**, not v3-core — **Reversibility:** costly — remappings, install string, and later diff suites bind to v4 API names (`getSqrtPriceAtTick` / `getTickAtSqrtPrice`); switching back to v3 renames every oracle call site.
- **D-02:** Pin **`Uniswap/v4-core@v4.0.0`** via forge install (tag SHA tip at discuss time: `e50237c…` on `v4.0.0`) — **Reversibility:** costly — bit-identity work should stay on a fixed release; floating `main` rejected.
- **D-03:** Interpret historical process phrase `forge install v3-core@0.8` as **solc 0.8 Forge project + official Uniswap TickMath lib** — resolved to v4-core because v4 is `pragma ^0.8.0` and matches the `@0.8` intent; Uniswap/v3-core has no `@0.8` tag.

### Solc / Foundry
- **D-04:** Default `evm/` profile targets **solc 0.8.x** (compatible with v4 `^0.8.0`).
- **D-05:** **No** 0.7.6 `additional_compiler_profiles` / `compilation_restrictions` for the TickMath lib (those were only needed for v3). Dropped after the v4 switch.

### Scope discipline (user confirmed)
- **D-06:** Finish Phase 1 as **scaffold-only**. The Seaport-pattern diff that uses Uniswap TickMath tests as client and compares against **EVM-adapted `SqrtGrid`** is **not** this phase — discuss/plan that in Phase 2+ (base) and Phase 4+ (suite / SqrtGrid side).

### the agent's Discretion
- Exact `foundry.toml` solc patch version (e.g. 0.8.26 vs 0.8.28) within 0.8.x
- Remapping alias names (`v4-core/=…` vs `uniswap/v4-core/=…`) as long as TickMath imports clearly
- Whether smoke is a tiny wrapper contract vs a one-line test that only compiles an import
- Updating ROADMAP/REQUIREMENTS wording from `v3-core@0.8` → `v4-core@v4.0.0` as a docs chore in plan/execute (decision is locked here)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project / phase
- `.planning/PROJECT.md` — HEVM bit-identical twin goals
- `.planning/REQUIREMENTS.md` — EVM-01, EVM-02 (wording still says v3-core@0.8; treat as superseded by D-01/D-02 for the install target)
- `.planning/ROADMAP.md` — Phase 1 success criteria (scaffold); Phases 2–6 for Seaport + SqrtGrid driver
- `.planning/STATE.md` — current position

### Research
- `.planning/research/HEVM-FORGE-TICKMATH.md` — Forge / Seaport / bridge process (bridge deferred to Phase 3)
- `.planning/research/SUMMARY.md` — research rollup
- `.planning/research/STACK.md` — stack notes
- `.planning/codebase/STACK.md` — codebase stack map
- `.planning/codebase/STRUCTURE.md` — repo layout

### Upstream oracle (external)
- `Uniswap/v4-core@v4.0.0` — `src/libraries/TickMath.sol` (`getSqrtPriceAtTick`, `getTickAtSqrtPrice`)
- `Uniswap/v4-core@v4.0.0` — `test/libraries/TickMath.t.sol` + `src/test/TickMathTest.sol` (corpus for **later** phases, not Phase 1)

### Pattern refs (deferred phases — do not implement in Phase 1)
- `/home/jmsbpp/apps/vol-markets/test/diff/PlankDiffTestBase.sol` — Seaport `DifferentialTest` base (Phase 2+)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No `evm/` Foundry tree in this repo yet — greenfield under `evm/`.
- Haskell `SqrtGrid` / plots / `stack test` stay **untouched** this phase.

### Established Patterns
- Vol-markets uses Foundry remappings + (for older libs) compiler profiles; **v4 needs only 0.8**.
- Seaport diff pattern exists outside this repo; import pattern known for Phase 2.

### Integration Points
- Phase 1 output is the remapping + build that Phase 2/4 will import for canonical TickMath.
- Public Haskell package remains HEVM-free until later phases rewrite SqrtGrid.

</code_context>

<specifics>
## Specific Ideas

- User clarified the **true TDD driver**: Seaport-pattern `.diff.t.sol` whose **client/corpus** is Uniswap’s TickMath tests and whose **other side** is EVM-adapted `SqrtGrid` — explicitly deferred; next discuss after Phase 1 plan/execute is `$gsd-discuss-phase 2` (or 4 for the suite).
- v4 API rename vs v3: `getSqrtRatioAtTick` → `getSqrtPriceAtTick`; `getTickAtSqrtRatio` → `getTickAtSqrtPrice`.

</specifics>

<deferred>
## Deferred Ideas

- Seaport `DifferentialTest` / `DiffTestBase` + smoke `.diff.t.sol` → **Phase 2**
- `evm-spec-bridge` submodule + `hevm.call` + BRIDGE-03 → **Phase 3**
- TickMath.diff suite over Uniswap TickMath.t.sol corpus; non-vacuity / skip doctrine → **Phase 4**
- Second side via HEVM / EVM-adapted SqrtGrid bit-identity → **Phases 5–6**
- Solc profile depth / CI / gitignore gray areas (not selected in discuss) — planner defaults OK unless they block scaffold

</deferred>

---

*Phase: 1-Forge `evm/` + v3-core*
*Context gathered: 2026-09-08*
