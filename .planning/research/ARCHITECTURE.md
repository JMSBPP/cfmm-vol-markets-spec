# Architecture Research

**Domain:** Hybrid HEVM bit-identity oracle for a Haskell EVM numeric twin  
**Researched:** 2026-09-08  
**Confidence:** HIGH for repository boundaries and build order; MEDIUM for the precise `hevm` package adapter API, which must be confirmed against the selected package version.

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│ Public numeric library: src/                                          │
│ SqrtGrid ──► fixed-point consumers ──► payoffs/liquidity/Panoptic     │
│ (pure, plot-free; no HEVM dependency)                                 │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ same typed fixture inputs/results
┌───────────────────────────────▼──────────────────────────────────────┐
│ HEVM oracle test component: hevm-test/                                │
│ Fixture corpus ─► Solidity reference bytecode ─► in-process HEVM      │
│       │                     │                    │                    │
│       └──────── Haskell result comparison ◄──── EVM word/revert ─────┘
└───────────────────────────────┬──────────────────────────────────────┘
                                │ independently gated evidence
┌───────────────────────────────▼──────────────────────────────────────┐
│ Existing consumers                                                     │
│ test/Spec.hs: fast pure regressions     plot/ + app/: unchanged PNGs  │
│ downstream packages: public library only                              │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Boundary |
|---|---|---|
| `src/SqrtGrid.hs` | Own EVM-compatible Q96, tick-to-sqrt, inverse-tick, and staged arithmetic semantics. | Pure public API; no bytecode, HEVM imports, Chart, or IO. |
| `src/` dependents | Consume stable `SqrtGrid` types/functions for liquidity, payoff, pricing, Panoptic, and volatility calculations. | Must not reimplement tick math or bypass its staged arithmetic. |
| `test/Spec.hs` | Retain fast, broad pure regressions and plot-layout checks. | Does not import HEVM or carry slow oracle setup. |
| `hevm-test/Fixtures` | Own deterministic boundary, rounding, overflow/revert, and corpus fixtures in a format usable by both Haskell and Solidity reference code. | Fixture data only; does not define production arithmetic. |
| `hevm-test/Oracle` | Run the compiled reference bytecode through in-process `EVM.hs`, normalize result/revert data, and compare it to the Haskell result. | Test-only adapter around the selected `hevm` API. |
| `hevm-test/Reference` | Minimal Solidity/reference-bytecode target exposing TickMath/FullMath-compatible calls. | Oracle target, not a production deployment or a second implementation of business logic. |
| `plot/`, `app/` | Continue to consume public `src/` APIs and render existing evidence. | Never depend on HEVM or oracle fixtures. |

## Recommended Project Structure

```text
src/
├── SqrtGrid.hs                    # rewritten authoritative Haskell numeric core
├── Liquidity/                     # consumers migrated after SqrtGrid parity
├── Payoffs/                       # consumers migrated after liquidity primitives
├── Panoptic/                      # encoding consumers, independently word-tested
└── ...
hevm-test/                         # new test-only component, not public library
├── Spec.hs                        # HEVM-specific test entry point
├── Fixtures.hs                    # typed, shared fixture corpus and expected outcomes
├── Oracle.hs                      # EVM.hs adapter and result normalization
├── Compare.hs                     # exact word/revert comparison helpers
└── Reference/
    ├── SqrtGridReference.sol      # minimal ABI surface for TickMath/FullMath
    └── SqrtGridReference.bin      # pinned compiled bytecode, or build-produced fixture
test/
└── Spec.hs                        # existing fast pure suite; add only pure SqrtGrid checks
plot/                              # unchanged visualization-only internal library
app/Main.hs                        # unchanged batch plot entry point
```

### Structure Rationale

- **`src/`:** preserves the package's plot-free public-library contract and keeps downstream consumers independent of HEVM, Solidity artifacts, and a symbolic evaluator.
- **`hevm-test/`:** isolates a comparatively heavy, version-sensitive test dependency and gives oracle failures their own executable, fixtures, and CI job.
- **`test/Spec.hs`:** remains the short feedback-loop suite; duplicating HEVM initialization inside its monolithic script would couple ordinary regressions to oracle tooling.
- **`Reference/`:** makes the EVM semantics auditable and versioned while preventing test bytecode or Solidity build mechanics from entering production Haskell modules.

## Architectural Patterns

### Pattern 1: Pure implementation with executable differential oracle

**What:** Rewrite the Haskell path in `SqrtGrid` using explicit EVM word/range/rounding behavior. For each fixture, evaluate both that Haskell path and a minimal EVM reference in HEVM; require exact equality of return words or equivalent failure.

**When to use:** For EVM-realizable numeric functions where “approximately correct” is unacceptable: TickMath conversion, FullMath-style `mulDiv`, Q96 multiplication/inversion, and later packed liquidity operations.

**Trade-offs:** It preserves Haskell ergonomics and plotting performance while supplying an EVM oracle. It does not prove the oracle bytecode or HEVM itself correct; retain known canonical test vectors and review the reference target.

### Pattern 2: Stable typed boundary with fixture adapters

**What:** Fixtures use domain types at the Haskell edge (`Tick`, `SqrtPriceX96`) and encode/decode only at the oracle adapter boundary to ABI words and calldata.

**When to use:** Always for an oracle test, so type intent remains visible and sign/width conversion occurs in one reviewed place.

**Trade-offs:** A small adapter is necessary. Passing untyped `Integer` lists through all tests would hide signedness, bounds, and revert expectations.

### Pattern 3: Dependency-ordered parity migration

**What:** Establish SqrtGrid parity before converting dependent calculations, then retain an oracle suite per migrated operation.

**When to use:** This milestone, because `sqrtPriceX96`, `tickFromSqrtPriceX96`, `mulX96`, and `mulDiv` sit beneath liquidity, payoff, pricing, and Panoptic paths.

**Trade-offs:** It delays broad claims of parity, but prevents downstream fixture failures from masking a foundational tick-math mismatch.

## Data Flow

### Oracle Fixture Flow

```
Typed fixture (tick / operands / expected success or revert)
        │
        ├──► src/SqrtGrid.hs ──► Haskell result or error classification
        │
        └──► hevm-test/Oracle.hs
                 │ ABI encode calldata
                 ▼
        SqrtGridReference bytecode in in-process HEVM (EVM.hs)
                 │
                 ▼
          return bytes / revert bytes / execution failure
                 │ ABI decode and normalize
                 ▼
          exact comparator: word, status, and fixture label
                 │
                 ├──► pass/fail HEVM test target
                 └──► diagnostic: inputs, Haskell result, EVM result
```

### Key Data Flows

1. **SqrtGrid reference flow:** a fixture exercises Haskell `sqrtPriceX96`, inverse tick lookup, or a Q96 arithmetic primitive and the equivalently scoped reference entry point. The comparator asserts exact integer/word identity—never a floating-point tolerance.
2. **Regression flow:** selected canonical and boundary fixtures are mirrored in `test/Spec.hs` as fast pure checks; the complete oracle corpus runs in the separate HEVM target.
3. **Consumer flow:** migrated dependents call only exported `SqrtGrid` functions. Existing `plot/` layouts and `app/Main.hs` receive the same public domain types and remain unaware of oracle execution.

### Fixture Categories

- Canonical TickMath vectors: tick `0`, known positive/negative ticks, and supported min/max ticks.
- Rounding boundaries: adjacent ticks, floor/ceiling transitions, and inverse lookup around exact returned sqrt-ratio words.
- Arithmetic boundaries: zero, Q96, max valid operands, denominator edge cases, and required overflow/revert behavior.
- Regression seeds: fixtures added for each discovered mismatch, labeled with the source issue/reference.

Fixtures must distinguish a valid zero result from an EVM revert. Haskell exceptions should be caught only in the oracle adapter and normalized to the fixture’s expected semantic outcome; production `src/` keeps its existing fail-fast contract until a deliberate API migration changes it.

## Build Order

1. **Define the oracle seam:** add a test-only Stack/package component with `hevm` and a separate executable/test stanza; keep the public `library` dependency list unchanged. Decide and pin the reference bytecode provenance (reproducible Solidity compiler invocation or a reviewed committed binary).
2. **Establish the SqrtGrid fixture corpus:** record canonical TickMath/FullMath vectors, supported tick range, exact signed/unsigned encoding rules, and expected reverts before changing calculations.
3. **Implement the minimal reference target and HEVM adapter:** expose only `getSqrtRatioAtTick`, `getTickAtSqrtRatio`, and necessary `mulDiv`/Q96 operation wrappers. Verify HEVM fixture execution independently with known words.
4. **Rewrite `src/SqrtGrid.hs`:** replace `Double`-based tick conversion and rounded inverse mapping on the EVM-gated path with integer/bitwise TickMath-compatible logic; specify where legacy mathematical `Double` helpers remain non-authoritative.
5. **Gate SqrtGrid parity:** run the HEVM suite plus existing `stack test` and plot executable. Preserve API compatibility or introduce explicitly named compatibility helpers only where plotting requires a real-valued view.
6. **Migrate direct dependents in dependency order:** `StrikeX96`/`State` and liquidity primitives (`LiquidityChunk`, `TickLiquidity`, `LiquidityGrid`), then payoff/replica paths, then pricing/volatility consumers. Add a focused oracle adapter and fixtures for each EVM-realizable operation.
7. **Treat independent boundaries separately:** keep Panoptic bit packing under its existing exact pure tests initially; add HEVM coverage only when a Solidity-compatible reference entry point is selected. Do not force continuum `VariancePortfolio` into the EVM oracle.
8. **Operationalize CI:** retain `stack test` as the fast baseline, add a separate HEVM parity job/target, and run plot generation as compatibility evidence where already required. A parity failure blocks only the claimed migrated operation, not unrelated visualization code.

## Scaling Considerations

| Scale | Architecture adjustment |
|---|---|
| Initial SqrtGrid wedge | One bytecode target, hand-curated fixtures, separate HEVM test executable. |
| Several migrated primitives | Group reference wrappers by domain, reuse ABI/result normalization, maintain fixture modules per primitive. |
| Large generated corpus | Deterministically generate and shrink fixtures, shard HEVM tests in CI, retain a small canonical smoke corpus for local runs. |

### Scaling Priorities

1. **First bottleneck:** HEVM execution time and diagnostic complexity; isolate it from the pure suite and use deterministic, labeled cases.
2. **Second bottleneck:** semantic drift between fixture encoding, Solidity reference, and Haskell implementation; centralize ABI conversion and pin reference provenance.

## Anti-Patterns

### Putting HEVM in the public library

**What people do:** Add `hevm`, bytecode loading, or oracle calls to `src/` or the public `library` dependencies.  
**Why it's wrong:** It violates the plot-free/lightweight consumer boundary and changes a pure numeric twin into test-runtime-coupled code.  
**Do this instead:** Keep HEVM entirely in the dedicated test component.

### Using plots or floating-point closeness as a parity test

**What people do:** Regard visually similar PNGs or `abs a-b < ε` as EVM identity evidence.  
**Why it's wrong:** Tick rounding and one-wei Q96 errors can be invisible in plots while changing on-chain behavior.  
**Do this instead:** Compare normalized EVM return/revert outcomes and Haskell words exactly; use plots only for consumer compatibility.

### Migrating dependents before SqrtGrid is proven

**What people do:** Modify payoffs, liquidity, and tick math together.  
**Why it's wrong:** A mismatch has no clear owner and can be “fixed” by compensating downstream rounding.  
**Do this instead:** Land and gate SqrtGrid first, then migrate consumers in the declared dependency order.

## Integration Points

### External Services

| Service | Integration pattern | Notes |
|---|---|---|
| Hackage `hevm` / `EVM.hs` | Test-only dependency and in-process evaluator adapter. | Pin a compatible version outside the LTS snapshot if needed; do not expose its types in public APIs. |
| Solidity compiler/reference source | Build or provide pinned bytecode for the HEVM fixture target. | Compiler version and optimizer settings are part of oracle provenance. |
| CI | Separate HEVM parity job beside existing Stack and Lean jobs. | The pure suite stays fast and independently actionable. |

### Internal Boundaries

| Boundary | Communication | Notes |
|---|---|---|
| `src/SqrtGrid` ↔ dependents | Pure typed Haskell functions | No consumer-owned duplicate tick/Q96 arithmetic. |
| `hevm-test/Fixtures` ↔ `src/SqrtGrid` | Typed fixtures and pure results | Fixtures exercise public semantics rather than internals. |
| `hevm-test/Oracle` ↔ reference bytecode | ABI calldata / return or revert bytes | Conversion, signedness, and error normalization live here. |
| `src/` ↔ `plot/`/`app/` | Existing public numeric API | Preserve this boundary; no HEVM import transitively reaches plots. |

## Sources

- `.planning/PROJECT.md` — milestone goals, constraints, and phase-1 SqrtGrid wedge.
- `.planning/codebase/ARCHITECTURE.md` — current layers, data flow, and public-library contract.
- `.planning/codebase/STRUCTURE.md` — existing layout and recommended HEVM harness isolation.
- `package.yaml` and `src/SqrtGrid.hs` — verified current dependency and implementation boundaries.

---
*Architecture research for: Hybrid HEVM bit-identity for Haskell SqrtGrid*  
*Researched: 2026-09-08*
