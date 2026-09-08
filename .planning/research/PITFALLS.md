# Pitfalls Research

**Domain:** EVM bit-identical Uniswap-style Q96/TickMath/`mulDiv` in Haskell with HEVM oracles  
**Researched:** 2026-09-08  
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Treating unbounded `Integer` arithmetic as EVM `uint256` arithmetic

**What goes wrong:**  
The Haskell implementation returns the mathematical quotient for inputs whose Solidity equivalent would revert, overflow, or fail a narrowing cast. Passing normal fixtures can then be mistaken for EVM parity even though the boundary behavior is different.

**Why it happens:**  
`Integer` does not overflow, whereas `FullMath.mulDiv` has explicit denominator and 256-bit-result constraints, and this codebase subsequently narrows liquidity/amounts with `checkU128`.

**How to avoid:**  
Make the oracle contract and Haskell wrapper expose the same success/revert result. Test `denominator = 0`, `denominator <= prod1`, maximum Q64.96 prices, and every `uint128` cast boundary. Preserve `FullMath`'s floor and revert semantics; do not replace them with arbitrary-precision division plus a late clamp.

**Warning signs:**  
Haskell accepts an input for which HEVM reverts; tests compare only successful values; `checkU128` occurs after a value has already been used; or a proposed `mulDiv` implementation has no result-width/revert tests.

**Phase to address:**  
Phase 1 — HEVM harness and shared `mulDiv` oracle contract.

---

### Pitfall 2: Collapsing canonical staged `mulDiv` chains into one algebraically equivalent expression

**What goes wrong:**  
Refactoring `mulDiv amt (mulDiv a b Q96) (b - a)` into `amt * a * b \`div\` ((b - a) * Q96)` changes the point at which floors occur. The result can differ by wei even with unbounded Haskell integers, and the latter product cannot be evaluated directly in the EVM.

**Why it happens:**  
Developers preserve real-number algebra but overlook integer truncation and `FullMath` staging. The asset-0 `legLiquidity` path and `legMintValue` are especially susceptible.

**How to avoid:**  
Treat each row of `docs/BITWIDTHS.md` as executable semantics: one `mulDiv` call per Solidity `FullMath.mulDiv`, followed only by the corresponding plain division. Add a golden vector that differs between staged and fused formulations for every multi-stage chain.

**Warning signs:**  
Bare `a*b*c \`div\` d`, a helper named “simplified” or “optimized,” removal of an intermediate Q96 floor, or a test suite that checks only approximate values.

**Phase to address:**  
Phase 2 — SqrtGrid and Q96 arithmetic rewrite.

---

### Pitfall 3: Porting TickMath with `Double`, logarithms, or a generic integer square root

**What goes wrong:**  
`sqrtPriceX96` agrees near tick zero but differs from `TickMath.getSqrtRatioAtTick`, often by one or more Q96 units at large positive/negative ticks. An inverse tick routine can also choose the wrong adjacent tick at a boundary.

**Why it happens:**  
`lambda ** (tick / 2)` and `floor` model the real number, not TickMath's precomputed constants, conditional multiplication order, Q128.128-to-Q64.96 round-up, and fixed tick range.

**How to avoid:**  
Transcribe the canonical TickMath bit-decomposition constants and operations exactly, including absolute-tick validation, reciprocal operation for positive ticks, and final round-up from the low 32 bits. Test `MIN_TICK`, `MAX_TICK`, zero, every power-of-two tick-bit branch, and `getTickAtSqrtRatio(getSqrtRatioAtTick(t)) == t` where the Solidity domain permits it.

**Warning signs:**  
Use of `Double`, `(**)`, `log`, or `sqrt` in HEVM-gated tick conversion; no assertions for `MIN_SQRT_RATIO`/`MAX_SQRT_RATIO`; equality tests stop at moderate ticks.

**Phase to address:**  
Phase 2 — TickMath-identical `SqrtGrid`.

---

### Pitfall 4: Checking only outputs, not EVM failure modes and input domains

**What goes wrong:**  
The oracle suite proves a small happy-path table but fails to establish whether inputs at tick, sqrt-ratio, denominator, signedness, or narrowing boundaries should succeed or revert. Later callers rely on Haskell values that cannot exist on-chain.

**Why it happens:**  
HEVM is used as a calculator rather than an executable specification. Haskell types such as `Integer` do not encode `uint24`, `int24`, `uint128`, or `uint160` by default.

**How to avoid:**  
Define domain constructors or checked smart constructors for EVM words, ticks, and Q64.96 ratios. Have each oracle case assert one of: exact word output, specific revert class, or invalid-input rejection before EVM invocation. Include invalid endpoints such as `MAX_SQRT_RATIO` for `getTickAtSqrtRatio`, whose Solidity precondition is strict.

**Warning signs:**  
Fixtures use plain `Integer` everywhere; negatives or values above `2^256-1` reach an encoder; test helpers discard revert data; or endpoint behavior is undocumented.

**Phase to address:**  
Phase 1 — oracle contract/API design, before porting callers.

---

### Pitfall 5: Using HEVM symbolic execution as if it were an exhaustive proof

**What goes wrong:**  
Symbolic evaluation either times out/path-explodes on 256-bit `mulDiv` and TickMath, or tests accidentally constrain inputs so tightly that they cover only a trivial path. A green symbolic run is then described as universal parity.

**Why it happens:**  
`FullMath.mulDiv` includes 512-bit emulation, branches, modular inversion, and revert paths. TickMath has many conditional multiplications; unconstrained symbolic words make HEVM work disproportionately hard.

**How to avoid:**  
Use concrete HEVM golden/differential tests for full-word edge vectors and stage-focused symbolic properties with explicit, documented bounds. Split properties by branch (no-overflow versus `prod1` path; each tick mask; each asset path). State the exact quantified domain; do not infer all-EVM proof from finite fixtures.

**Warning signs:**  
Long or flaky HEVM runs, solver timeouts treated as passes, `assume` filters that remove boundary values, or reports saying “proved” without a domain and solver result.

**Phase to address:**  
Phase 1 — oracle-test architecture and CI budget.

---

### Pitfall 6: Mixing Q96 values with untyped raw integers or wrong rounding direction

**What goes wrong:**  
Code passes an unscaled price to `mulDiv`, shifts by 96 twice, or uses ceiling where Uniswap rounds down (or vice versa for Panoptic closing amounts). The numeric magnitude can look plausible in plots while mint amounts and boundary payoffs are wrong.

**Why it happens:**  
Q64.96 is dimensionally a scaled sqrt price; `Integer` makes prices, liquidity, token amounts, and scale factors interchangeable. TickMath's final conversion deliberately rounds up, whereas the documented `chunkAmount0/1` paths floor.

**How to avoid:**  
Keep `SqrtPriceX96`, liquidity, and token amount newtypes at arithmetic boundaries; centralize Q96 conversion; encode rounding direction in helper names and tests. Assert known rounding-sensitive vectors around non-divisible products and document the exceptional Panoptic rounding-up path separately.

**Warning signs:**  
Literal `2^96` scattered across modules; `div`/`ceiling` used directly in payoff code; ratio conversions through `Double`; or tests use only exactly divisible cases.

**Phase to address:**  
Phase 2 — typed numeric core; Phase 3 — replica/Panoptic caller migration.

---

### Pitfall 7: Leaving `OptionRatio` and strike construction on `Double` while claiming SqrtGrid parity

**What goes wrong:**  
Tick-to-sqrt values are exact in isolation, but a `Double` width ratio or `sqrt` strike constructor moves a chunk boundary or midpoint by a wei. The four-leg replica then produces a HEVM mismatch even though `SqrtGrid` tests pass.

**Why it happens:**  
The current code distinguishes an EVM-like `SqrtPriceX96` layer from older analytic paths using `OptionRatio Double`. The mismatch appears only when these towers meet.

**How to avoid:**  
Define the SqrtGrid milestone boundary precisely: HEVM-gated paths must derive ratios and strikes with integers (`integerSqrt` and staged division), while retained plot-only `Double` paths are visibly segregated and cannot feed oracle fixtures. Resolve the Panoptic 7-bit option-ratio mapping before testing density-to-chunk parity.

**Warning signs:**  
An oracle-path import of `OptionRatio`; `fromIntegral`, `sqrt`, or `floor` in `StrikeX96`/RAN geometry; tolerances justified as “floating-point noise”; or Haskell/HEVM mismatches concentrated at chunk endpoints.

**Phase to address:**  
Phase 3 — integer strike/ratio boundary migration, after SqrtGrid baseline.

---

### Pitfall 8: Oracling the non-realizable continuum portfolio rather than the deployed replica

**What goes wrong:**  
The project spends effort attempting to HEVM-check `VariancePortfolio`/`ln` diagnostics, then treats that as evidence for a Panoptic mint path. No EVM counterpart exists for the continuum object, so the result neither proves deployment behavior nor provides a sound oracle.

**Why it happens:**  
The continuum variance portfolio is the mathematical reference, while `VolatilityReplica.fourLegReplica`, chunks, and mint plans are the realizable objects; their names and output shapes are close enough to conflate.

**How to avoid:**  
Restrict v1 oracle vectors to `fourLegReplica`, `legMintValue`, `LiquidityChunk` amounts, and `Panoptic.Binning` outputs. Keep `VariancePortfolio` and `ErrorX96` as off-chain regression baselines, labeled non-EVM-realizable in tests and exports.

**Warning signs:**  
HEVM test plans mention `ln`, RMS replica error, or a continuum integral as a contract target; test success lacks a corresponding Solidity function; or a deployment call is derived from T0 output.

**Phase to address:**  
Phase 1 — scope lock and oracle fixture inventory.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `Double` TickMath approximation | Simple plots and quick prototypes | Irreconcilable EVM boundary drift | Plot-only, behind a non-oracle API |
| Fuse staged `mulDiv`s | Fewer helpers/shorter code | Changes floor semantics and hides EVM overflow branches | Never on an EVM-identical path |
| Happy-path HEVM fixtures only | Fast initial integration | Reverts, casts, and extreme tick errors escape | Only as a temporary smoke test with a tracked expansion |
| Put HEVM in public library dependencies | Simple import topology | Breaks the plot-free downstream library contract and consumer builds | Never; test-only/optional component |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Stack LTS 24.55 + `hevm` | Add HEVM to the default public dependency set and assume it is snapshot-compatible | Pin it as a test-only extra dependency or dedicated Stack config; verify GHC 9.10.3 resolution before changing public components |
| HEVM oracle ABI | Encode Haskell `Integer` as a word without range/sign validation | Validate ABI widths and signedness before encoding; compare decoded `uint256` words and revert outcomes |
| Solidity reference | Use a locally modified helper or a convenience implementation rather than canonical TickMath/FullMath semantics | Pin the reference source/bytecode and record its compiler/settings and function selectors with fixtures |
| Downstream `evm_spec_rpc` | Import HEVM/plot dependencies through the public spec library | Keep HEVM harness under `test/` or an internal optional component; retain the existing plot-free library seam |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Fully symbolic `mulDiv` over unconstrained words | Solver timeouts, memory growth, nondeterministic CI duration | Concrete edge corpus plus bounded, branch-local symbolic properties | Immediately on the 512-bit product/remainder path |
| Per-case EVM initialization | Thousands of fixtures dominate `stack test` time | Deploy/load reference bytecode once per test group and batch calls where the HEVM API allows | Large tick sweeps or property runs |
| Exhaustive all-tick cross-product tests | CI spends most time on oracle calls without new branch coverage | Cover all ticks only in a scheduled job; use endpoints, bit-mask cases, and deterministic sampled ticks in PR CI | 1,774,545 ticks times multiple functions/branches |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Equating arbitrary-precision success with on-chain success | Off-chain planner emits liquidity/amounts that revert or truncate on-chain | Mirror word bounds, revert conditions, and `uint128` narrowing in Haskell and HEVM tests |
| Dropping TickMath's strict sqrt-ratio endpoint guard | A caller accepts a ratio Solidity rejects and maps it to a misleading tick | Test and enforce `MIN_SQRT_RATIO <= ratio < MAX_SQRT_RATIO` for the inverse function |
| Treating 1-wei differences as harmless | A boundary mismatch selects a different tick/leg and can alter a mint plan | Require exact equality for EVM-gated values; tolerances only for explicitly off-chain analytic outputs |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Reporting plots as EVM-parity evidence | Researchers assume visually identical curves imply executable equality | Report oracle status separately, including function, domain, reference bytecode, and exact vector count |
| Silent fallback from HEVM failure to Haskell result | A test consumer sees a plausible answer instead of an unsupported/reverting EVM path | Surface an explicit oracle/revert result and fail test cases without an expected outcome |
| Mixing analytic and bit-identical APIs under the same name | Callers unknowingly choose a `Double` path for mint geometry | Name/segregate diagnostic numeric paths and document oracle-qualified entry points |

## "Looks Done But Isn't" Checklist

- [ ] **HEVM harness:** Often missing reference-bytecode provenance and revert assertions — verify exact canonical contract source, compiler settings, and success/revert parity.
- [ ] **`mulDiv`:** Often missing `prod1`/denominator and narrowing-cast boundaries — verify direct and staged chains at all documented BITWIDTHS extremes.
- [ ] **TickMath:** Often missing the final Q128.128→Q64.96 round-up and strict inverse endpoint — verify min/max/zero, bit-mask branches, and round trips.
- [ ] **SqrtGrid rewrite:** Often leaves `Double` ingress through strikes/ratios — verify oracle fixtures have no `OptionRatio Double`, `sqrt`, or floating conversion in their call graph.
- [ ] **Replica oracle:** Often validates T0 continuum diagnostics rather than the mintable four-leg path — verify every oracle-tested result maps to a real Solidity/Panoptic operation.
- [ ] **Build integration:** Often leaks HEVM or plot dependencies into the public library — verify the library-only downstream build remains green.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Fused `mulDiv` changed rounding | MEDIUM | Restore each documented stage, generate a distinguishing regression vector, and audit callers for equivalent algebraic rewrites |
| TickMath differs at extremes | MEDIUM | Replace floating implementation with canonical constants/order, add endpoint vectors, then migrate dependent fixtures |
| Haskell accepts EVM-reverting inputs | HIGH | Introduce checked domain/result types, preserve failure outcomes in API/tests, and revalidate all generated mint plans |
| HEVM symbolic suite times out | LOW | Split by branch, constrain justified domains, retain concrete boundary corpus, and move exhaustive runs to scheduled CI |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| `Integer` differs from EVM word/revert semantics | Phase 1 — HEVM harness | Exact success/revert differential corpus, including width and denominator boundaries |
| Fused staged `mulDiv` | Phase 2 — SqrtGrid arithmetic rewrite | Golden cases distinguishing staged and fused floors for every BITWIDTHS chain |
| Non-canonical TickMath | Phase 2 — TickMath-identical SqrtGrid | Canonical endpoint/bit-branch vectors and permitted tick↔ratio round trips |
| Symbolic path explosion/false confidence | Phase 1 — oracle-test architecture | Bounded property manifest, timeout failure policy, concrete edge-corpus coverage |
| Q96 scale/rounding confusion | Phase 2 — typed numeric core | Rounding-sensitive vectors and no raw Q96 arithmetic in oracle paths |
| `Double` ratio/strike leaks | Phase 3 — replica geometry migration | Static call-graph audit plus exact HEVM endpoint fixtures |
| Continuum object used as target | Phase 1 — scope lock | Fixture inventory maps each case to an EVM-realizable Solidity operation |
| Public-library dependency leak | Phase 1 — build integration | Library-only and downstream seam builds remain green |

## Sources

- `PROJECT.md` — milestone scope, hybrid replacement decision, constraints, and EVM-realizable boundary.
- `.planning/codebase/CONCERNS.md` — current `Double` leaks, HEVM dependency risk, fragile staged chains, and consumer seam.
- `docs/BITWIDTHS.md` — canonical staged formulas, operand bounds, rounding rules, and explicitly off-chain paths.
- Uniswap V3 `TickMath` and `FullMath` semantics — canonical reference behavior to pin in the HEVM oracle suite.

---
*Pitfalls research for: EVM bit-identical Uniswap-style Q96/TickMath/`mulDiv` in Haskell with HEVM oracles*  
*Researched: 2026-09-08*
