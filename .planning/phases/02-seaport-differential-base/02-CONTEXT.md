# Phase 2: Seaport differential base - Context

**Gathered:** 2026-09-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Stand up Seaport-style differential infrastructure under the existing `evm/` Foundry project and land a **skeleton `HevmDiffTest`** that uses Uniswap’s TickMath test client shape, with the HEVM/Haskell side intentionally RED until the bridge lands.

**Delivers (EVM-03 + skeleton):**
- `ProjectOpenSea/seaport@1.6` installed; `@seaport/=lib/seaport/test/foundry/` remapping
- Dedicated top-level `forge-std` remapped for `Test.sol`
- Thin `DiffTestBase` (Seaport `DifferentialTest` + `diffComparisons` / `_requireComparisonRan` / `_runDiff`)
- Skeleton `HevmDiffTest` in `evm/test/diff/TickMath.Hevm.diff.t.sol` with one real Uniswap `test_*` name
- `evm/src/HevmTickMathHarness.sol` stub that reverts (HEVM not wired)
- CI: recursive submodules; pin asserts for seaport (+ forge-std); `forge build` green; assert HevmDiffTest still fails

**Does not deliver:** full TickMath corpus (Phase 4), `evm-spec-bridge` / live `hevm.call` (Phase 3), SqrtGrid bit-identity (Phases 5–6).

</domain>

<decisions>
## Implementation Decisions

### DifferentialTest source
- **D-01:** `forge install` **ProjectOpenSea/seaport** (not a vendored-only copy of the util).
- **D-02:** Pin **`ProjectOpenSea/seaport@1.6`** — **Reversibility:** costly — remappings and CI pin asserts bind to this release.
- **D-03:** Remapping **`@seaport/=lib/seaport/test/foundry/`** (vol-markets parity).
- **D-04:** Install a **dedicated** `evm/lib/forge-std` with explicit `forge-std/=lib/forge-std/src/` so harness + diffs share one `Test.sol` (avoid relying solely on nested forge-std from v4-core/seaport).

### HevmDiffTest / client architecture
- **D-05:** Core pattern: Uniswap TickMath tests as **client**; suite is **`HevmDiffTest`** with Seaport-style `FuzzArgs` + `Context` and external `fn(Context, FuzzArgs)`; **same `test_*` names** as upstream; Side B is a harness that will only **`hevm.call` → Haskell** (wired later).
- **D-06:** Phase 2 ships a **skeleton `HevmDiffTest` now** (not base-only): TickMath-shaped context, one real `test_*`, HEVM side RED/stub.
- **D-07:** Bring Uniswap client via **remapping/import from installed `v4-core`**, not a vendored copy of the test file.
- **D-08:** Prefer inheriting / mirroring **`TickMathTestTest`** (`test/libraries/TickMath.t.sol`) for same-named `test_*`; use **`TickMathTest`** (`src/test/TickMathTest.sol`) as the Solidity/library exposure harness for Side A — **Reversibility:** costly if naming drifts from upstream.
- **D-09:** Phase 2 HEVM stub **reverts** (e.g. `"hevm.call not wired"`) so comparison fails loudly (TDD RED).

### Smoke / skeleton suite
- **D-10:** First vector: **`test_getSqrtPriceAtTick_isValidMinTick`** (non-FFI, non-gas).
- **D-11:** File: **`evm/test/diff/TickMath.Hevm.diff.t.sol`**.
- **D-12:** Treat **compile + intentional fail** as Phase 2 success for the suite; document in `evm/README`.

### Layout
- **D-13:** **`evm/test/diff/DiffTestBase.sol`** + suite under `test/diff/`; **`evm/src/HevmTickMathHarness.sol`** for the HEVM stub.
- **D-14:** Remaps keep **`evm/src` for our harness only**; import Uniswap via `v4-core/…` (or dedicated aliases) without collapsing our `src/` onto v4-core’s `src/`.

### CI
- **D-15:** Required gate remains **`forge build --root evm`** green (after recursive submodule init).
- **D-16:** Gating step runs `forge test --match-contract HevmDiffTest` (or equivalent) and **asserts non-zero exit** (still RED).
- **D-17:** Add **pin asserts** for `seaport@1.6` and top-level `forge-std` (alongside existing v4-core pin).

### the agent's Discretion
- Exact forge-std version/tag compatible with Seaport 1.6 + solc 0.8.28
- Exact revert error type/string for the HEVM stub
- Whether DiffTestBase is named `DiffTestBase` vs `HevmDiffTestBase`
- Precise remapping alias strings for v4-core test/harness imports
- Exact `forge test --match-*` filter string for the CI RED assert

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project / phase
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md` — EVM-03 (this phase); TICK-* / BRIDGE-* deferred
- `.planning/ROADMAP.md` — Phase 2 section
- `.planning/STATE.md`
- `.planning/phases/01-forge-evm-v3-core/01-CONTEXT.md` — prior locks (v4-core@v4.0.0, scaffold-only predecessor)
- `.planning/phases/01-forge-evm-v3-core/01-SUMMARY.md` — what Phase 1 built

### Research / pattern
- `.planning/research/HEVM-FORGE-TICKMATH.md` — Seaport / vol-markets differential notes
- `/home/jmsbpp/apps/vol-markets/test/diff/PlankDiffTestBase.sol` — helper pattern (no Plank deps here)
- `/home/jmsbpp/apps/vol-markets/test/types/VegaTarget.diff.t.sol` — inherit original test as client + swap oracle

### Upstream
- `ProjectOpenSea/seaport@1.6` — `test/foundry/utils/DifferentialTest.sol`
- `Uniswap/v4-core@v4.0.0` — `src/test/TickMathTest.sol`, `test/libraries/TickMath.t.sol`

### Local scaffold
- `evm/foundry.toml`, `evm/src/TickMathHarness.sol`, `.github/workflows/ci.yml`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 1 `evm/` with `TickMathHarness`, `v4-core@v4.0.0`, CI recursive submodules + forge build
- Vol-markets Seaport remapping and DiffTestBase helpers (copy pattern, not Plank)

### Established Patterns
- Seaport `DifferentialTest.stateless` + `assertPass` for swap-context diffs
- Non-vacuity via `diffComparisons` counter

### Integration Points
- Phase 3 will replace HEVM stub body with real `hevm.call`
- Phase 4 expands corpus to remaining Uniswap `test_*` names

</code_context>

<specifics>
## Specific Ideas

- User architecture: client = Uniswap TickMath tests; `HevmDiffTest { TickMathTest… }`; external `fn(Context, FuzzArgs)`; same test names; other side = harness that only `hevm.call` to Haskell.
- First skeleton case: `test_getSqrtPriceAtTick_isValidMinTick`.

</specifics>

<deferred>
## Deferred Ideas

- Live `hevm.call` / `evm-spec-bridge` submodule → **Phase 3**
- Full Uniswap TickMath.t.sol corpus mapping → **Phase 4**
- SqrtGrid bit-identity twin → **Phases 5–6**
- Making HevmDiffTest CI-green → only after bridge wires Side B

</deferred>

---

*Phase: 2-Seaport differential base*
*Context gathered: 2026-09-08*
