
## Done

1. ~~Find the .md that ties \(r^{\phi}=\phi\,\delta_{\mathrm{trans}}\) under `~/cfmms-playground/cfmm-wt/` and copy to `refs/`~~
   - `refs/VOLATILITY_INTRUMENTS_MEV.md` (eq. ~L337)

2. ~~Is \(\pi^{\phi}\) built?~~
   - **Base yes:** `Payoffs.TransactionalFeeCapture` — \(\pi^\phi=\phi_X P+\phi_M I\); sum along tenor; Swap identity; `fee-capture-*-vs-*.png`
   - Parametrized / ref-scalar pieces → open below

3. ~~κ path C~~ — `KappaTick` / `KappaSpacing` (\(N=255\)), `snapKappaTick`; B `KappaPips` retired

4. ~~`ExpectedReturn` + \(\pi^{\Delta Q}(r^e)\) mixture~~ — `ReturnFromKappa` (FeeStructure / FeePips); `runSwapAlongTenorMixture`

---

## Open

### Pricing / returns / fee-revenue

5. **Parametrized fee capture** \(\pi^\phi(r_\phi^e)\)
   - \((1-r_\phi^e)\,\phi_X P + r_\phi^e\,\phi_M I\)
   - Construct \(r_\phi^e = \phi\cdot r^e\) with \(\phi=\phi_M\otimes\phi_X\) (`toFeePips`)
   - Wire like Swap mixture; keep base `TransactionalFeeCapture` as \(r_\phi^e\)-free legs

6. **`ExpectedReturn` composition / nonzero \(r(0)\)**
   - `ExpectedReturn <>` Realized (and other expecteds) → that sum *is* future \(r(0)\) before κ-scaling
   - FeePips path today is through-origin (\(r=\kappa\phi\)); VISIBLE NOTE in `Pricing.ExpectedReturn`

7. **Ref transactional return** \(r^\phi=\phi\,\delta_{\mathrm{trans}}\)
   - Distinct from payoff \(\pi^\phi\); scope in `refs/VOLATILITY_INTRUMENTS_MEV.md`
   - Decide: scalar control return type vs leave in notes only

8. **`MarkUpStructure` superclass; `FeeStructure` as instance**
   - `FeeStructure` today is a concrete bag `{φ_X, φ_M}`
   - Introduce a class (name pin: `MarkUpStructure`) that abstracts markup bags; `FeeStructure` implements it
   - Goal: other markup shapes (one-sided, adaptive Θ-driven, …) share `ReturnFromKappa` / capture constructors without hard-wiring `FeeStructure`
   - Brainstorm before implement (typeclass vs data family vs newtype hierarchy)

9. **`AdaptiveStremia` body** — still stub \(\phi(\Theta_\phi;\sigma^2,\nu)\)

### Package / tree moves (README `//` notes; not done)

10. **`Panoptic/` package** — move `NId.hs`, `MintPlan.hs` (and dependents as needed) out of `Payoffs/`

11. **`Plotting/` package** — move `PlotSqrt.hs`, `PlotInterest.hs`, `PlotUtils.hs` out of `Payoffs/` / root

12. **Rename** `CPMMPosition` → `CLMMPosition`

13. **`TargetVega`** — move out of `Payoffs/` (README: outside)

### Liquidity / density (pre-existing)

14. **Chunk × density EVM mul** (Bunni/Panoptic) — `LiquidityDensity` / `TickLiquidity` TODOs; geometric \(L\) only so far

15. **Density → Panoptic `optionRatio` brainstorm** — see `docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md`

### Hygiene

16. **Commit / PR** scratchpad WIP on `main` (κ C, ExpectedReturn, TransactionalFeeCapture, README tree, `refs/`, this TODO) when ready — currently uncommitted
