# Feature Research

**Domain:** HEVM-proven, bit-identical EVM numeric twin for CFMM volatility-market arithmetic
**Researched:** 2026-09-08
**Confidence:** HIGH for the SqrtGrid v1 boundary and existing-code constraints; MEDIUM for HEVM packaging details until the selected Hackage version builds under GHC 9.10.3.

## Feature Landscape

### Table Stakes (Must Have)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Canonical `TickMath.getSqrtRatioAtTick` port | `sqrtPriceX96` is the foundation of every tick-indexed EVM path; the current `Double` exponentiation and `floor` cannot be bit-identical. | MEDIUM | Port the integer constant-multiply / reciprocal / round-up algorithm over the full Uniswap V3 tick domain; preserve the existing `SqrtGrid` API. |
| Exact Solidity-word semantics at public boundaries | A claimed EVM twin must reject or model invalid tick, zero-divisor, signedness, and uint-width behavior deterministically. | MEDIUM | Define an explicit EVM-realizable input domain and test it. `Integer` may implement the calculation, but it must not silently accept values Solidity rejects. |
| `FullMath.mulDiv` oracle coverage | The existing Haskell `mulDiv` computes an unbounded integer result; it needs evidence that each admitted EVM path agrees with the Solidity semantics and rounding direction. | MEDIUM | Start with concrete HEVM executions / golden vectors for `mulDiv` and SqrtGrid's staged operations. Include exceptional/revert cases where the Solidity reference defines them. |
| In-process, test-only HEVM harness | The requested proof boundary needs a repeatable oracle local to the Haskell package, without adding HEVM or plotting dependencies to the public library. | MEDIUM | Add HEVM only to a test/optional component, with pinned dependency configuration compatible with Stack LTS 24.55 and GHC 9.10.3. |
| Boundary and adversarial vector suite | Normal-price fixtures do not detect the known one-wei drift or 160-bit / 512-bit edge cases. | MEDIUM | Cover min/max ticks, zero, ±1, tick-spacing boundaries, extreme Q64.96 ratios, `mulDiv` carry/overflow boundaries, and expected failure paths. |
| Stable plot and consumer compatibility regression | The product promise explicitly preserves plots, `stack test`, and pure-library downstream consumers. | LOW | Retain exported names and plotting `Double` conversion boundary; run existing regression suite plus a plot smoke/regression check. |
| Bit-identity scope ledger | Future modules contain known `Double` leaks and non-realizable theory. Without a machine-readable or reviewable boundary, “bit-identical” will be overclaimed. | LOW | Update `docs/BITWIDTHS.md` (or linked test manifest) to mark exact, oracle-tested, deferred, and intentionally off-chain paths. |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Differential property testing against HEVM | Goes beyond a few hand-picked vectors by generating legal ticks and EVM words, shrinking disagreements to minimal counterexamples. | HIGH | Requires a concrete Solidity/reference-bytecode entry point and generators constrained to uint160/uint256 and valid TickMath range. |
| Proof-carrying fixture corpus | Versioned fixtures record Haskell input/output, EVM output/revert, reference bytecode hash, and semantic version. This makes parity reproducible across dependency upgrades. | MEDIUM | A strong complement to live HEVM tests; regenerate only through an explicit command and review fixture diffs. |
| Intermediate-stage witness tests | Checking only final values can miss a rewritten `mulDiv` staging sequence that coincidentally agrees on sampled cases. | HIGH | Expose test-only traces or reference helper calls for critical chains such as chunk amounts and replica leg liquidity. Keep tracing out of the public API. |
| Explicit numeric-domain types and constructors | Separating `Tick`, Q64.96, uint128 liquidity, uint160 sqrt price, and uint256 arithmetic prevents invalid values from reaching the twin and documents Solidity correspondence. | HIGH | Introduce incrementally behind compatibility constructors; do not undertake the broader `OptionRatio` rewrite in SqrtGrid v1. |
| Cross-layer parity ladder | Reuses the SqrtGrid harness for `LiquidityChunk`, `CLMMPosition`, and four-leg replica mint plans, while preserving T0 continuum calculations as off-chain diagnostics. | HIGH | Depends on SqrtGrid exactness, the test harness, and resolving the chunk×density and integer-ratio design gaps. |
| Downstream adapter smoke contract | A pinned `evm_spec_rpc` / cfmm-adapter compile or fixture check catches package-seam and API regressions before consumers discover them. | MEDIUM | Must remain an optional cross-repository CI job; public library stays plot- and HEVM-free. |

### Anti-Features (Deliberately NOT Build in v1)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Run all `src/` functions inside an EVM | It sounds like the simplest definition of parity. | Much of `src/` is analytic or visualization-oriented; `VariancePortfolio` is explicitly continuum and not EVM-realizable. It would expand scope and break the hybrid design. | Rewrite only EVM-realizable hot paths in Haskell; use HEVM as their oracle. Keep T0 as an off-chain regression baseline. |
| Replace every `Double` immediately | Eliminates a visible source of drift. | `OptionRatio`, RAN, Greeks, plots, and κ paths span many modules and require unresolved economic/design choices. Mixing that refactor with SqrtGrid makes failures uninterpretable. | Close the SqrtGrid leak first; document deferred leaks; schedule integer `OptionRatio` and strike work as a subsequent dependency-led phase. |
| Add HEVM to the public library dependencies | Makes HEVM seem universally available to consumers. | Violates the plot-free/lightweight library seam and risks Stack/GHC conflicts in downstream packages. HEVM is verification infrastructure, not runtime behavior. | Isolate it in a test suite or optional internal component. |
| Treat unbounded Haskell `Integer` as automatically EVM-equivalent | It makes ports compact and tests may pass for ordinary inputs. | Solidity reverts or wraps at fixed widths and `FullMath` has an admissible-result constraint; unbounded calculations can silently certify unreachable states. | Validate EVM ranges and assert reference reverts/results through HEVM. |
| Tolerance-based “near enough” parity assertions | Existing analytic tests use tolerances and it reduces initial test failures. | A tolerance defeats the core bit-identity claim, especially at tick and payoff discontinuities. | Exact word/revert equality on HEVM-gated paths; retain tolerances only for explicitly off-chain analytic/plot diagnostics. |
| Foundry↔HEVM relay product work | A broader relay could be useful for external integration. | It belongs to `evm_spec_rpc`, has independent operational concerns, and is out of this milestone's local verification wedge. | Define a narrow local bytecode/fixture adapter now; integrate with the relay only after SqrtGrid parity is established. |

## Feature Dependencies

```text
[Canonical TickMath port]
    └──requires──> [Explicit EVM input-domain policy]
                           └──requires──> [Boundary/adversarial vectors]

[HEVM test-only harness]
    └──requires──> [Stack/GHC-compatible HEVM dependency pin]
    └──enables───> [FullMath and TickMath oracle coverage]
                           └──enables───> [Differential property testing]
                           └──enables───> [Proof-carrying fixture corpus]

[Exact SqrtGrid parity]
    └──requires──> [Canonical TickMath port]
    └──requires──> [HEVM oracle coverage]
    └──enables───> [Cross-layer parity ladder]

[Integer OptionRatio / chunk×density design]
    └──requires──> [Approved density-to-Panoptic ratio mapping]
    └──blocks────> [Bunni/LiquidityChunk parity expansion]

[Whole-src EVM execution] ──conflicts──> [Hybrid Haskell rewrite plus HEVM oracle]
[Tolerance-based parity] ──conflicts──> [Bit-identity acceptance criterion]
```

### Dependency Notes

- **Exact SqrtGrid parity requires both the TickMath port and HEVM oracle coverage:** a faithful-looking integer port without an independent EVM execution remains an unverified transcription.
- **HEVM coverage requires a compatible dependency pin before implementation work can be trusted in CI:** `hevm` is not in the current Stack snapshot, so wiring must be validated before tests become a release gate.
- **Property testing follows deterministic vectors:** curated extrema establish the reference contract and make harness failures diagnosable; generated testing then extends the search space.
- **Cross-layer parity requires SqrtGrid first:** chunk bounds, strikes, and four-leg geometry depend on tick-to-sqrt conversion, so downstream mismatches cannot be attributed cleanly beforehand.
- **Bunni/LiquidityChunk expansion is blocked by the integer ratio and density design:** SqrtGrid completion does not resolve the currently undecided `OptionRatio` representation or missing staged density multiply.

## MVP Definition

### Launch With (v1)

- [ ] Canonical integer `sqrtPriceX96` / TickMath port over the valid tick domain — removes the phase-1 `Double` leak while preserving the consumer-facing API.
- [ ] Test-only HEVM reference harness with pinned build configuration — makes EVM evaluation repeatable in this repository.
- [ ] Exact HEVM golden tests for TickMath and `mulDiv`, including extrema and revert behavior — establishes the bit-identity claim.
- [ ] Existing `stack test` and plot regression/smoke evidence — validates the hybrid rewrite's compatibility promise.
- [ ] Exactness/deferred-scope ledger in `docs/BITWIDTHS.md` — prevents SqrtGrid evidence from being misrepresented as whole-`src/` parity.

### Add After Validation (v1.x)

- [ ] HEVM differential property tests — add once deterministic reference bytecode and the test harness are stable.
- [ ] Test-only intermediate-stage traces — add when staged `mulDiv` chains in `LiquidityChunk` or replica minting enter the parity boundary.
- [ ] `LiquidityChunk`, `CLMMPosition`, and four-leg replica oracle suites — add after each path has an agreed Solidity reference and SqrtGrid is green.
- [ ] Downstream adapter smoke test — add when a stable cross-repository pinning/CI boundary is agreed.

### Future Consideration (v2+)

- [ ] Integer `OptionRatio` and `StrikeX96` migration — defer until the density-to-Panoptic mapping decision resolves semantic ownership and migration shape.
- [ ] Bunni density × chunk parity — defer until the staged formula and validity predicate are implemented.
- [ ] Expected-return / κ path parity — defer until measure and expectation types replace the current `Double` coordinate work.
- [ ] Foundry↔HEVM relay product integration — defer to the bridge project after local verification delivers value.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Canonical TickMath SqrtGrid port | HIGH | MEDIUM | P1 |
| Test-only HEVM harness and exact oracle vectors | HIGH | MEDIUM | P1 |
| Boundary/revert coverage and domain policy | HIGH | MEDIUM | P1 |
| Compatibility and exactness-scope regressions | HIGH | LOW | P1 |
| Differential property tests | HIGH | HIGH | P2 |
| Fixture corpus and stage witnesses | MEDIUM | MEDIUM/HIGH | P2 |
| Cross-layer replica parity ladder | HIGH | HIGH | P2 |
| Integer OptionRatio and density path | HIGH | HIGH | P3 |
| Whole-source EVM execution | LOW | HIGH | P3 (excluded) |

## Competitor / Reference Feature Analysis

| Feature | Uniswap V3 core reference | HEVM | Our Approach |
|---------|---------------------------|------|--------------|
| Tick-to-sqrt calculation | `TickMath.getSqrtRatioAtTick` defines integer constants, bounds, and Q64.96 round-up semantics. | Executes deployed/reference bytecode under EVM semantics. | Port the TickMath algorithm into `SqrtGrid`; assert exact word/revert equality against HEVM. |
| Full-precision multiplication/division | `FullMath.mulDiv` specifies 512-bit intermediate handling and floor result/revert conditions. | Evaluates the reference implementation, including exceptional execution. | Preserve explicit staged Haskell `mulDiv` chains; validate both final values and high-risk bounds against HEVM. |
| Verification style | Solidity unit/fuzz tests demonstrate implementation behavior but are not a Haskell twin. | Concrete and symbolic EVM evaluation supplies an independent oracle. | Use HEVM for test-only differential verification while keeping the Haskell core fast, pure, and plot-compatible. |
| Numeric scope | EVM-realizable contract arithmetic only. | EVM program behavior only. | Deliberately distinguish EVM-realizable replica paths from analytic `Double`/continuum research code. |

## Sources

- `PROJECT.md` — project scope, hybrid decision, compatibility contract, and phase-1 requirements (2026-09-08).
- `.planning/codebase/CONCERNS.md` — known numeric leaks, dependency risks, test gaps, and explicitly non-realizable paths (2026-09-08).
- `src/SqrtGrid.hs` — current Q96 helpers and non-identical `Double` tick conversion (reviewed 2026-09-08).
- Uniswap V3 Core, `TickMath.sol` and `FullMath.sol` — canonical EVM reference behavior for tick/Q64.96 and full-precision division.
- HEVM (`EVM.hs`) — in-process EVM evaluator intended as the local oracle.

---
*Feature research for: HEVM-proven EVM bit-identical SqrtGrid, then EVM-realizable `src/` paths*
*Researched: 2026-09-08*
