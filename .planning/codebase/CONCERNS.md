# Codebase Concerns

**Analysis Date:** 2026-09-08

Focus: technical debt and risks relevant to an upcoming **HEVM port** and to downstream consumers (`evm_spec_rpc` / `evm-spec-bridge`).

---

## Tech Debt

**HEVM not wired into the build:**
- Issue: `package.yaml` and `stack.yaml` have no `hevm` (or `hevm-cabal`) dependency; no test target exercises symbolic EVM execution against Haskell reference values.
- Files: `package.yaml`, `stack.yaml` (LTS 24.55 only; no `extra-deps` for HEVM)
- Why: Spec work has been Haskell-first with Foundry as the on-chain twin; HEVM integration lives in a separate repo (`/home/jmsbpp/apps/evm_spec_rpc`, design `docs/superpowers/specs/2026-09-08-foundry-hevm-relay-design.md`) and is not yet linked back into this tree.
- Impact: No automated proof that staged `mulDiv` chains in `SqrtGrid` match EVM semantics; HEVM diff tests cannot run from this repo without new Stack wiring and a relay peer.
- Fix approach: Add `hevm` as an optional/test-only extra-dep; introduce a `hevm` internal library or `test/` suite that compares reference outputs for EVM-realizable paths (`VolatilityReplica`, `CLMMPosition.fromChunk`, `LiquidityChunk` amount functions) via the Foundry↔HEVM relay; keep the public library plot-free per `package.yaml` comment.

**`OptionRatio` is `Double`, not EVM-faithful:**
- Issue: `newtype OptionRatio = OptionRatio Double` — width ratio \(r = b/a\) is stored and compared as IEEE float, not as a rational or fixed-point word.
- Files: `src/OptionRatio.hs` (definition); consumers include `src/Payoffs/CLMMPosition.hs`, `src/Payoffs/RangeAccrualNote.hs`, `src/StrikeX96.hs`, `src/Greeks/Delta.hs`, `src/Greeks/Gamma.hs`, `src/Panoptic/NId.hs`, `src/Panoptic/LegChunk.hs`, `plot/Plot/**`, `test/Spec.hs` (~15 modules total)
- Why: Kristensen bound-setting \(r\) was prototyped before Panoptic 7-bit `optionRatio` semantics were pinned; brainstorm for density→ratio mapping is still open (`TODO.md` #11, `src/Liquidity/LiquidityDensity.hs` header).
- Impact: Tick snapping and RAN arm boundaries can drift from on-chain `getSqrtRatioAtTick` / integer ratio by ulps; HEVM assertions on chunk geometry will fail unless tolerance is widened or `OptionRatio` is replaced with `Rational` or `(num, den)` integers.
- Fix approach: Split Kristensen \(r\) from Panoptic 7-bit ratio; represent chunk width as `integerRatio :: (Integer, Integer)` derived from `SqrtPriceX96` bounds (`b/a` without `Double`); reserve `OptionRatio` rename or removal per `docs/BITWIDTHS.md` "Known Double leaks" table.

**`StrikeX96` uses `Double` `sqrt` in strike constructors:**
- Issue: `strike` for two sqrt prices uses `floor (sqrt (pa * pb :: Double))`; `Strike SqrtPriceX96 OptionRatio` uses `floor (pa * sqrt r)`.
- Files: `src/StrikeX96.hs` (lines 23–33)
- Why: Predates TODO #28 Item 0 integer strike work; `CLMMPosition.strikeAndRatio` already uses `integerSqrt` for \(k_{1/2}\) but still feeds `OptionRatio Double` for \(r\).
- Impact: Strike coordinates on the sqrt grid may differ from Uniswap V3 `TickMath` by 1 wei; propagates into RAN, delta, and four-leg replica mint geometry.
- Fix approach: Route all strike math through `SqrtGrid.integerSqrt` and ratio via integer division; align with `src/Payoffs/CLMMPosition.hs` comment at lines 55–56.

**`sqrtPriceX96` tick→price uses `Double` exponentiation:**
- Issue: `sqrtPrice i = lambda ** (fromIntegral i / 2)` then `floor` to Q96 — not bit-identical to `TickMath.getSqrtRatioAtTick`.
- Files: `src/SqrtGrid.hs` (lines 97–102)
- Why: Convenient for plots and early grid generation; documented as a budgeted leak in `docs/BITWIDTHS.md`.
- Impact: Any HEVM test that compares tick-indexed prices against Solidity will see systematic 1-wei (or worse) drift at large \(|i|\).
- Fix approach: Port Uniswap V3 tick→sqrtRatio256 algorithm (or call it via relay); restrict `sqrtPriceX96` to test/plot boundaries only.

**`RangeAccrualNote` and Greeks arms still on `Double`:**
- Issue: `lowerBound`/`upperBound`/`lowerArmNumerator`/`upperArmNumerator` use `sqrt r`; `cpmmDelta` uses `sqrt (k*r/p)` in the in-range branch.
- Files: `src/Payoffs/RangeAccrualNote.hs`, `src/Greeks/Delta.hs`, `src/Greeks/Gamma.hs`
- Why: RAN closed forms were written for analytic plots before integer discipline was enforced.
- Impact: \(\pi^{\mathrm{RAN}}\) and CLMM identity witness tests pass in Haskell but may not match EVM `PositionValue` at boundaries; delta/gamma used by `Payoffs.ReplicaDelta` finite-difference checks inherit the leak.
- Fix approach: Express RAN arms with `integerSqrt` and staged `mulDiv` per `docs/BITWIDTHS.md`; keep `Double` only in `plot/` and regression tolerances.

**`Trading/KappaCoordinate` — partial stub, `Double` on Def 45 path:**
- Issue: Module is implemented for κ encoding C (uint8 lattice) but `kappaFromTick`, `snapKappaTick`, and `kappaAt` use `Double` for real κ and η conversion; visible note defers π^φ(r_φ^e) and `ExpectedReturn` composition.
- Files: `src/Trading/KappaCoordinate.hs`, `src/Pricing/ExpectedReturn.hs` (deferred r(0) note)
- Why: Lane A transients shipped with through-origin FeePips; measure/expectation prereqs (#17–#18) not built.
- Impact: κ-scaled returns are not yet HEVM-checkable against on-chain fee accrual; not on the critical replica path but blocks full `r_{\Delta Q}^e` closure for RPC adapters.
- Fix approach: Integer κ as `(j, N)` only on-chain; keep `Double` snap confined to plot/tests until #17–#21 land.

**Continuum `VariancePortfolio` vs realizable `VolatilityReplica`:**
- Issue: `Payoffs.VariancePortfolio` (T0) uses continuous `logPortfolioQ96` — explicitly "REFERENCE / DIAGNOSTIC ONLY" and "NOT EVM-realizable"; production replica is T2 `Payoffs.VolatilityReplica.fourLegReplica` (+ T1 `Payoffs.LadderPosition`).
- Files: `src/Payoffs/VariancePortfolio.hs`, `src/Payoffs/VolatilityReplica.hs`, `src/Payoffs/LadderPosition.hs`, `README.md` Def 7
- Why: Carr–Madan continuum limit is the theory anchor; Panoptic 4-leg position is the deployable instrument.
- Impact: HEVM port scope must not target T0 `ln` portfolio on-chain; `ErrorX96` / `replicaError` are marked off-chain in `docs/BITWIDTHS.md`. Accidentally porting T0 would ship unrealizable logic.
- Fix approach: HEVM golden vectors from `fourLegReplica`, `legMintValue`, `Panoptic.Binning.mintPlanFromLadder`; treat T0 as regression baseline only (TODO #29).

**Chunk × density EVM multiply — open (TODO #10):**
- Issue: `Liquidity.TickLiquidity.tickLiquidityAt` implements geometric \(L(\mathrm{hi})/L(\mathrm{lo})=\xi\) only; `mulDiv(ΔQ_v, ℓ(x), Q96)` for rung liquidity is not implemented; density→chunk / density→Panoptic `optionRatio` brainstorm unresolved.
- Files: `src/Liquidity/TickLiquidity.hs` (line 25 deferral), `src/Liquidity/LiquidityDensity.hs`, `src/Liquidity/LiquidityGrid.hs`, `src/Payoffs/LadderPosition.hs` (`ladderChunks`), `TODO.md` #10/#11
- Why: Bunni `ILiquidityDensityFunction` mapping awaits approved design (`docs/superpowers/specs/2026-08-24-scratchpad-ladder-replication-design.md` §3).
- Impact: T1 ladder mint sizing cannot be HEVM-checked against Bunni until staged multiply exists; binning (`Panoptic.Binning`) may silently diverge from on-chain LDF queries.
- Fix approach: Implement `mulDiv(ΔQ_v*, ℓ(x), Q96)` with validity predicate from ladder spec; complete optionRatio brainstorm before porting density layer.

**Repository hygiene — `.worktrees/` and `core/` artifacts:**
- Issue: `.worktrees/draft-option-ratio-ldf/` duplicates ~255 files (full tree copy); not in `.gitignore`. `core/src/` holds stale `.o`/`.hi` (e.g. `SqrtGrid.o`, 56 KB, Aug 2025) under a partial module tree.
- Files: `.worktrees/**`, `core/src/SqrtGrid.o`, `.gitignore` (ignores `*.o` but not `.worktrees/` or `core/`)
- Why: Local git worktree for draft LDF work; ad-hoc `core/` compile experiment.
- Impact: Grep/search noise, risk of editing the worktree copy instead of `src/`; stale objects confuse file watchers and disk audits; agents may map wrong paths for HEVM port.
- Fix approach: Add `.worktrees/` to `.gitignore`; remove or document `core/` as non-build artifact; prefer single-branch workflow per `AGENTS.md`.

---

## Known Bugs

**No tracked reproducers filed as GitHub bugs for HEVM drift:**
- Symptoms: Integer vs `Double` paths can disagree by 1 Q96 wei at chunk boundaries (documented, not filed as runtime bug).
- Trigger: Compare `CLMMPosition.fromChunk` payoff at \(p = k_{1/2}\) vs Uniswap reference at same ticks when `OptionRatio` uses float division.
- Workaround: Tests use generous X96 tolerances; `integerSqrt` strike path reduces but does not eliminate drift while \(r\) stays `Double`.
- Root cause: Mixed numeric towers (Integer Q96 + Double ratio + floor).
- Blocked by: TODO #10/#11 and OptionRatio integer refactor.

---

## Security Considerations

**Downstream seam — spec must stay out of core bridge packages:**
- Risk: Accidentally adding `cfmm-vol-markets-spec` to a core `evm-spec-bridge-*` component breaks the spec-less CI config and pulls Chart/cairo into headless builds.
- Files: `package.yaml` (lines 40–44: plot-free public library contract); external consumer `/home/jmsbpp/apps/evm_spec_rpc/scripts/seam-guard.sh`, `stack-core.yaml`
- Current mitigation: `evm_spec_rpc` enforces CFMM-01 — only `components/cfmm-adapter` may `build-depends` on the spec; negative test exits on violation.
- Recommendations: Any HEVM test harness added here should live in `test/` or a new optional component, not expand the public library surface; pin commits consumed by `evm_spec_rpc/stack.yaml.lock` when changing EVM-realizable modules.

**Fixed-point overflow discipline:**
- Risk: Bare `a*b*c \`div\` d` bypasses 512-bit staging; on-chain overflow or wrong floor vs Solidity `FullMath.mulDiv`.
- Files: `src/SqrtGrid.hs` (`mulDiv`), `docs/BITWIDTHS.md` (transcription table)
- Current mitigation: New model code documented to use staged `mulDiv`; table maps Haskell→Solidity per function.
- Recommendations: HEVM tests should assert intermediate bounds from `docs/BITWIDTHS.md` for `chunkAmount0/1`, `legLiquidity`, `legMintValue`, `hedgeStep`.

---

## Performance Bottlenecks

**Monolithic `test/Spec.hs` IO script:**
- Problem: Single long IO test module pulls entire spec + plot internal library; full suite rebuilds on any src change.
- Files: `test/Spec.hs`, `package.yaml` test stanza
- Measurement: Not profiled in this audit; CI runs `stack test` on ubuntu-latest (Lean CI separate, 7 min noted in `TODO.md` #37).
- Cause: Integration-style regression script rather than split unit tests.
- Improvement path: Extract EVM-realizable golden tables into small pure modules testable without Chart; HEVM suite can import those tables only.

**`replicaError` window sweep:**
- Problem: RMS over tick window W is O(|W|) per optimizer step; documented \(\approx S^2\) scaling (Corollary 4, README).
- Files: `src/Payoffs/VolatilityReplica.hs`, `README.md` REPLICATION_THEORY
- Measurement: \(e^\sigma_W(\mathcal B)=2.1\times10^{-4}\) at S=4000, \(\Delta_i=10\)
- Cause: Off-chain surface by design (`ErrorX96` — no EVM bound in `docs/BITWIDTHS.md`).
- Improvement path: Keep off-chain; do not port to HEVM.

---

## Fragile Areas

**Bitwidth / `mulDiv` staging chain:**
- Files: `docs/BITWIDTHS.md`, `src/SqrtGrid.hs`, `src/Payoffs/VolatilityReplica.hs` (`legMintValue`), `src/Liquidity/LiquidityChunk.hs`, `src/Hedge/Ledger.hs`, `src/Payoffs/LvrRate.hs`
- Why fragile: Single refactor from staged to naive multiply changes Solidity twin semantics; `legLiquidity` asset=0 path is explicitly **not** bit-equal to single-stage form.
- Common failures: New code uses bare `div`; second `/ a` in `chunkAmount0` mistaken for `mulDiv`.
- Safe modification: Copy staged form from BITWIDTHS table; add row before implementing; run existing chunk amount regressions in `test/Spec.hs`.
- Test coverage: Amount functions covered; HEVM symbolic execution not present.

**Four-leg replica mint geometry (`Panoptic.Binning` + `LegChunk`):**
- Files: `src/Panoptic/Binning.hs`, `src/Panoptic/LegChunk.hs`, `src/Payoffs/VolatilityReplica.hs`
- Why fragile: `or(leg) ∈ {1..127}`, 12-bit width, token1 basis (`asset = 1`) — Panoptic constraints bind many fields; quantization report must stay consistent with mint plan.
- Common failures: Off-by-one tick on leg bounds; wrong token type branch in `legMintValue`.
- Safe modification: Run `quantizationReport` and Corollary 4 equal-notional checks before changing binning.
- Test coverage: Regressions in `test/Spec.hs`; panels under `outputs/Payoffs/Replica/` (gitignored).

**CLMM identity / \(\pi^{\varphi}\) decomposition:**
- Files: `src/Payoffs/CLMMPosition.hs`, `src/Payoffs/PathAccrual.hs`, `README.md` Theorem 3
- Why fragile: Normalization is per-chunk `amount0`, not per tick; rebate holder path (#89–#92) composes trans/holder/arb legs.
- Common failures: Conflating transactional fee return with MEV-doc notation (explicitly forbidden in `TODO.md`).
- Safe modification: Keep scratchpad symbol spellings; cite MEV note for economics only.
- Test coverage: CLMM witness test merged (TODO #24); Aristotle Lean twin pending peer C1–C3.

**Greeks stubs (`Theta`, `Vega`):**
- Files: `src/Greeks/Theta.hs`, `src/Greeks/Vega.hs`
- Why fragile: Placeholder `newtype` with function fields; open TODO on dimensionality and vega→liquidity map.
- Common failures: Treating stubs as implemented greeks for RPC or HEVM.
- Safe modification: Do not expose via public API to `cfmm-adapter` until defined; `ReplicaDelta` is the closed-form delta path for rebate tests.
- Test coverage: `Payoffs.ReplicaDelta` tested against `deltaOfPayoff`; Theta/Vega untested.

---

## Scaling Limits

**Panoptic liquidity words:**
- Current capacity: `L ≤ 2^128`, `amt ≤ 127·2^128`, sqrt prices ≤ 2^160 (Q64.96)
- Limit: `docs/BITWIDTHS.md` — `n_max < 2^135` for `positionSize = n_max/127`
- Symptoms at limit: `createChunk` uint128 guard failure; binning overflow in `n_leg` sum
- Scaling path: Not applicable on-chain; off-chain optimizer must respect same bounds in HEVM tests

**Public library vs plot split:**
- Current capacity: Downstream builds compile only `library:` (no Chart/cairo)
- Limit: Adding Chart to public `dependencies` breaks `evm_spec_rpc` Docker/core builds
- Symptoms: CI failure in consumer; seam guard may not catch package-level dep moves
- Scaling path: Keep visualization in `internal-libraries: plot` only (`package.yaml` lines 48–55)

---

## Dependencies at Risk

**Git-pinned spec consumption (`evm_spec_rpc`):**
- Risk: Consumer pins `d2p-finance/cfmm-vol-markets-spec` at commit `f2736e0…` (`/home/jmsbpp/apps/evm_spec_rpc/stack.yaml`); API or module moves in scratchpad break adapter builds silently until bump.
- Impact: JSON-RPC registry and `cfmm-adapter` fail to compile; Phase 7 semantic wiring blocked.
- Migration plan: Coordinate spec bumps with `stack.yaml.lock` update in consumer; maintain plot-free public API.

**Stackage LTS 24.55 / GHC 9.10.3:**
- Risk: HEVM package may not be in snapshot; requires `extra-deps` and possible GHC version pinning conflict with consumer.
- Impact: Cannot add HEVM to default build without snapshot override.
- Migration plan: Optional stack flag or separate `stack-hevm.yaml` mirroring consumer's `stack-core.yaml` pattern.

**Lean CI vs Haskell CI:**
- Risk: Dual proof surfaces (`lean/vol_markets/` + Haskell) can diverge (peer follow-ons O(Δi) bound, off-midpoint strike — README Propositions 1–2).
- Impact: HEVM port may prove Haskell paths that Lean has not machine-checked.
- Migration plan: Cross-reference theorem names in test descriptions; prioritize Lean-pending items before claiming EVM parity.

---

## Missing Critical Features

**HEVM execution harness in this repo:**
- Problem: No symbolic EVM runner, no property tests against Solidity twins.
- Current workaround: Foundry tests in `clamm-automaton`; Haskell spec validated by `test/Spec.hs` integer regressions.
- Blocks: Bit-exact verification of port; Foundry↔HEVM relay exists only in `evm_spec_rpc` design doc (2026-09-08).
- Implementation complexity: Medium — Stack extra-dep + relay CLI + golden vectors for realizable subset.

**Integer `OptionRatio` / Panoptic 7-bit ratio map:**
- Problem: Density→`optionRatio` brainstorm not approved (`TODO.md` #11); `OptionRatio` remains Kristensen `Double`.
- Current workaround: `Panoptic.Binning` computes `or(leg)` from rung notionals directly, bypassing `OptionRatio` type.
- Blocks: HEVM tests on Bunni LDF × chunk multiply; clean Solidity transcription of width ratio.
- Implementation complexity: Medium — design approval then refactor ~15 modules.

**Chunk × density EVM multiply (TODO #10):**
- Problem: `mulDiv(ΔQ_v*, ℓ(x), Q96)` not implemented; validity predicate documented but not enforced in code path to on-chain LDF.
- Current workaround: T1 ladder uses geometric `ell` with uniform rung liquidity formula in `Payoffs.LadderPosition`.
- Blocks: Bunni-realizable T1 mint plans vs Haskell ladder parity under HEVM.
- Implementation complexity: Medium — staged mul + tests per BITWIDTHS row.

**Measure / expectation types (#17–#18):**
- Problem: No `DiscountFactor` or typed `Expectation`; blocks full `r_{\Delta Q}^e` composition (#6) and norm C reweighting (Corollary 3).
- Current workaround: Mixture weights hand-built in path accrual and holder path modules.
- Blocks: RPC methods that expose ex-ante expected returns, not just ex-post accrual.
- Implementation complexity: High — prerequisite chain in `TODO.md` execution order.

---

## Test Coverage Gaps

**HEVM / EVM bit-exact paths:**
- What's not tested: Symbolic execution of `mulDiv` chains vs `FullMath.mulDiv`; tick→sqrtRatio vs `TickMath`.
- Risk: Silent drift between Haskell reference and on-chain deployment discovered only in manual Foundry runs.
- Priority: High (for HEVM port)
- Difficulty: Requires hevm dep + relay infrastructure from `evm_spec_rpc`

**`OptionRatio` / `Double` sqrt boundaries:**
- What's not tested: Systematic 1-wei boundary sweep comparing float vs integer strike/RAN at all tick spacings.
- Risk: Four-leg replica mint at extreme ticks wrong leg liquidity.
- Priority: High
- Difficulty: Medium — pure Integer test module, no HEVM required

**Greeks `Theta` / `Vega`:**
- What's not tested: Everything (stubs only).
- Risk: Future RPC greeks endpoints ship undefined behavior.
- Priority: Low (until exposed)
- Difficulty: Low once economic definitions pinned

**T0 `VariancePortfolio` mistaken for production path:**
- What's not tested: Explicit guard that CI/deploy scripts never call T0 constructors for mint planning.
- Risk: Wrong object ported to Solidity/HEVM.
- Priority: Medium
- Difficulty: Low — lint or module export audit

**Downstream `cfmm-adapter` integration:**
- What's not tested: In-repo tests for JSON-RPC encoding of `VolOrder`, tick math, bit-packing ( lives in `evm_spec_rpc` ).
- Risk: Spec changes break adapter without local signal in scratchpad CI.
- Priority: Medium
- Difficulty: Cross-repo CI job or pinned adapter smoke test

---

*Concerns audit: 2026-09-08*
*Update as issues are fixed or new ones discovered*
