
## Done

1. ~~Find the .md that ties \(r^{\phi}=\phi\,\delta_{\mathrm{trans}}\) under `~/cfmms-playground/cfmm-wt/` and copy to `refs/`~~
   - `refs/VOLATILITY_INTRUMENTS_MEV.md` (eq. ~L337)

2. ~~Is \(\pi^{\phi}\) built?~~
   - **Base yes:** `Payoffs.TransactionalFeeCapture` — \(\pi^\phi=\phi_X P+\phi_M I\); sum along tenor; Swap identity; `fee-capture-*-vs-*.png`
   - Parametrized / ref-scalar pieces → open below

3. ~~κ path C~~ — `KappaTick` / `KappaSpacing` (\(N=255\)), `snapKappaTick`; B `KappaPips` retired

4. ~~`ExpectedReturn` + \(\pi^{\Delta Q}(r^e)\) mixture~~ — `ReturnFromKappa` (FeeStructure / FeePips); `runSwapAlongTenorMixture`

5. ~~**Parametrized fee capture** \(\pi^\phi(r_\phi^e)\)~~ — `feat` — [#1](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/1) / [#14](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/14)
   - `feeRevenueExpectedReturn` (\(r_\phi^e=\phi\cdot r^e\)); `runFeeCaptureAlongTenorMixture`

---

## Open

Workflow: see `AGENTS.md` / `CLAUDE.md` / `QWEN.md` (classify → branch → issue → PR → cross-comment).

| TODO | Type | Issue | PR |
|------|------|-------|-----|
| 6 | `feat` | [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2) | [#15](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/15) |
| 7 | `feat` | [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3) | [#16](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/16) |
| 8 | `feat` | [#4](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/4) | [#17](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/17) |
| 9 | `feat` | [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) | [#18](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/18) |
| 10 | `refactor` | [#6](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/6) | [#19](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/19) |
| 11 | `refactor` | [#7](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/7) | [#20](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/20) |
| 12 | `refactor` | [#8](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/8) | [#21](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/21) |
| 13 | `refactor` | [#9](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/9) | [#22](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/22) |
| 14 | `feat` | [#10](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/10) | [#23](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/23) |
| 15 | `docs` | [#11](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/11) | [#24](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/24) |
| 16 | `chore` | [#12](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/12) | [#13](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/13) |

### Pricing / returns / fee-revenue

6. **`ExpectedReturn` composition / nonzero \(r(0)\)** — `feat` — [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2)
   - `ExpectedReturn <>` Realized (and other expecteds) → that sum *is* future \(r(0)\) before κ-scaling
   - FeePips path today is through-origin (\(r=\kappa\phi\)); VISIBLE NOTE in `Pricing.ExpectedReturn`

7. **Ref transactional return** \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) — `feat` — [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3)
   - Distinct from payoff \(\pi^\phi\); scope in `refs/VOLATILITY_INTRUMENTS_MEV.md`
   - Decide: scalar control return type vs leave in notes only

8. **`MarkUpStructure` superclass; `FeeStructure` as instance** — `feat` — [#4](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/4)
   - `FeeStructure` today is a concrete bag `{φ_X, φ_M}`
   - Introduce a class (name pin: `MarkUpStructure`) that abstracts markup bags; `FeeStructure` implements it
   - Goal: other markup shapes (one-sided, adaptive Θ-driven, …) share `ReturnFromKappa` / capture constructors without hard-wiring `FeeStructure`
   - Brainstorm before implement (typeclass vs data family vs newtype hierarchy)

9. **`AdaptiveStremia` body** — `feat` — [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) — still stub \(\phi(\Theta_\phi;\sigma^2,\nu)\)

### Package / tree moves (README `//` notes; not done)

10. **`Panoptic/` package** — `refactor` — [#6](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/6) — move `NId.hs`, `MintPlan.hs` out of `Payoffs/`

11. **`Plotting/` package** — `refactor` — [#7](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/7) — move `PlotSqrt.hs`, `PlotInterest.hs`, `PlotUtils.hs`

12. **Rename** `CPMMPosition` → `CLMMPosition` — `refactor` — [#8](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/8)

13. **`TargetVega`** — `refactor` — [#9](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/9) — move out of `Payoffs/`

### Liquidity / density (pre-existing)

14. **Chunk × density EVM mul** — `feat` — [#10](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/10)

15. **Density → Panoptic `optionRatio` brainstorm** — `docs` — [#11](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/11)

### Hygiene

16. **Commit / PR** scratchpad WIP — `chore` — [#12](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/12)
