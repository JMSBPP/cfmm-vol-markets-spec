
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

6. ~~**Rename** `CPMMPosition` → `CLMMPosition`~~ — `refactor` — [#8](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/8) / [#21](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/21)
   - Module `Payoffs.CLMMPosition`; `clmmEtaLayout`; plot series labels

7. ~~**Move** `TargetVega` out of `Payoffs/`~~ — `refactor` — [#9](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/9) / [#22](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/22)
   - Top-level module `TargetVega` (`src/TargetVega.hs`)

---

## Open

Workflow: see `AGENTS.md` / `CLAUDE.md` / `QWEN.md` (classify → branch → issue → PR → cross-comment).

### Execution order (ascending semantic impact)

**TODO numbers are stable IDs** (they match existing GitHub issues). They are **not** priority.

We execute **least semantically impactful first**: renames and package moves before type/econ changes; new return/measure algebra last. `#6` stays blocked until `#17`–`#21` land.

| Exec | TODO | Why this wave |
|------|------|----------------|
| ~~1~~ | ~~**12**~~ | ~~Rename `CPMMPosition` → `CLMMPosition`~~ — **done** |
| ~~2~~ | ~~**13**~~ | ~~Move `TargetVega` out of `Payoffs/`~~ — **done** |
| 3 | **10** | `Panoptic/` package move (`NId`, `MintPlan`) — tree only |
| 4 | **11** | `Plotting/` package move — tree only |
| 5 | **16** | Chore: land/PR scratchpad WIP so trees stay clean |
| 6 | **8** | `MarkUpStructure` / `FeeStructure` — **refactor** of markup bag API (no new return law) |
| 7 | **15** | Docs brainstorm (density → `optionRatio`) — no code semantics |
| 8 | **14** | Chunk × density EVM mul — local numeric feat |
| 9 | **9** | `AdaptiveStremia` body — fills stub; still before measure/return stack |
| 10 | **17** | `DiscountFactor` / \(m(\cdot)\) — new measure type |
| 11 | **18** | `Expectation` constructors — depends on **17** |
| 12 | **19** | Exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) (scratchpad notation only) |
| 13 | **7** | Ref \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) — align with **19**; same notation rule |
| 14 | **20** | \(\sigma_{IV}\) stand-in (\(V(t)\) gap) |
| 15 | **21** | Parametric \(r_{\Delta Q_{\mathrm{arb}}}^{e}\) (+ \(\beta\)) — depends on **20** |
| — | **6** | **Blocked** until **17–21**; then `ExpectedReturn <>` / nonzero \(r(0)\) |

Later (after **19**+**21**, not numbered yet): compose \(r_{\Delta Q}^{e}\); wire \(\pi^{\Delta Q}/\pi^{\phi}\); unblock **6**.

| TODO | Type | Issue | PR | Status | Exec |
|------|------|-------|-----|--------|------|
| 6 | `feat` | [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2) | [#15](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/15) | **blocked** (prereqs 17–21) | — |
| 7 | `feat` | [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3) | [#16](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/16) | open | 13 |
| 8 | `refactor` | [#4](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/4) | [#17](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/17) | open | 6 |
| 9 | `feat` | [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) | [#18](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/18) | open | 9 |
| 10 | `refactor` | [#6](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/6) | [#19](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/19) | open | 3 |
| 11 | `refactor` | [#7](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/7) | [#20](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/20) | open | 4 |
| 14 | `feat` | [#10](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/10) | [#23](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/23) | open | 8 |
| 15 | `docs` | [#11](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/11) | [#24](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/24) | open | 7 |
| 16 | `chore` | [#12](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/12) | [#13](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/13) | open | 5 |
| 17 | `feat` | — | — | open (no GitHub issue yet) | 10 |
| 18 | `feat` | — | — | open (no GitHub issue yet) | 11 |
| 19 | `feat` | — | — | open (no GitHub issue yet) | 12 |
| 20 | `feat` | — | — | open (no GitHub issue yet) | 14 |
| 21 | `docs`→`feat` | — | — | open (no GitHub issue yet) | 15 |

### Pricing / returns / fee-revenue

6. **`ExpectedReturn` composition / nonzero \(r(0)\)** — `feat` — [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2) / [#15](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/15) — **BLOCKED / deferred** (exec —)
   - Parked until measure / expectation / return-split prereqs (**#17–#21**) exist
   - Then: `ExpectedReturn <>` Realized (and other expecteds) → that sum *is* future \(r(0)\) before κ-scaling
   - FeePips path today is through-origin (\(r=\kappa\phi\)); VISIBLE NOTE in `Pricing.ExpectedReturn`
   - Do **not** implement #6 while brainstorming #17–#21

7. **Ref transactional return** \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) — `feat` — [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3) (exec 13)
   - Distinct from payoff \(\pi^\phi\); scope in `refs/VOLATILITY_INTRUMENTS_MEV.md`
   - Decide: scalar control return type vs leave in notes only
   - **Notation:** keep scratchpad \(r^\phi\) / \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) language; do **not** adopt MEV-doc \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) labels (wrong)
   - Run after / alongside **#19** (same exogenous-trans family)

8. **`MarkUpStructure` superclass; `FeeStructure` as instance** — `refactor` — [#4](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/4) (exec 6)
   - `FeeStructure` today is a concrete bag `{φ_X, φ_M}`
   - Introduce a class (name pin: `MarkUpStructure`) that abstracts markup bags; `FeeStructure` implements it
   - Goal: other markup shapes (one-sided, adaptive Θ-driven, …) share `ReturnFromKappa` / capture constructors without hard-wiring `FeeStructure`
   - Low semantic impact: reshapes API, does **not** change return laws; brainstorm typeclass vs data family vs newtype hierarchy before implement

9. **`AdaptiveStremia` body** — `feat` — [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) — still stub \(\phi(\Theta_\phi;\sigma^2,\nu)\) (exec 9)

### Measure / expectation / \(r_{\Delta Q}^{e}\) split (README affine story; prereqs for #6)

Canonical split (scratchpad README notation — **required**):

\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})
\]

**Do not** rename these to MEV-doc \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) (or similar); that notation is wrong. MEV note may be cited for economics only.

17. **`DiscountFactor` / measure \(m(\cdot)\)** — `feat` (exec 10)
   - Parametric type (README: `DiscountFactor.hs`); indexes \(\Delta Q\) and/or \(\phi\)
   - Feeds \(\mathbb E[m\cdot\pi]\) for swap and fee-revenue expected returns
   - No GitHub issue until this TODO is accepted / brainstormed

18. **`Expectation` constructor types** — `feat` (exec 11)
   - Typed \(\mathbb E[m\cdot\pi]\) object (not only hand-built mixture weights)
   - Depends on #17
   - No GitHub issue yet

19. **Exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\)** — `feat` (exec 12)
   - **MUST** keep this symbol / spelling in code, tests, issues, and docs
   - Orthogonal to directional price moves; volatility-measured (arbs not directional)
   - Cite MEV note for motivation only — **never** adopt its \(\Delta\pi_{\mathrm{trans}}\) naming
   - Decide: first-class return type vs notes-only scalar control
   - No GitHub issue yet

20. **\(\sigma_{IV}\) stand-in** — `feat` (exec 14)
   - Raw Kristensen: \(\sigma_{IV}(t)=2\phi\sqrt{V(t)/L(i(t))}\)
   - Have `TickLiquidity`; **no** \(V(t)\) volume yet — brainstorm: volume type, ξ/liquidity workaround, or fitted u88-dimensional parameter (\(88=24+64\))
   - No GitHub issue yet

21. **Parametric \(r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})\)** (+ scalar \(\beta\)) — `docs` then `feat` (exec 15)
   - Endogenous arb expected return; \(\sigma^{e}\) = private vol expectation
   - Depends on #20; brainstorm functional form before implement
   - No GitHub issue yet

Later (not opened yet): compose \(r_{\Delta Q}^{e}\) from #19+#21; wire into parametrized \(\pi^{\Delta Q}/\pi^{\phi}\); then unblock #6.

### Package / tree moves (README `//` notes; not done) — exec 3–4

10. **`Panoptic/` package** — `refactor` — [#6](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/6) — move `NId.hs`, `MintPlan.hs` out of `Payoffs/` (exec 3)

11. **`Plotting/` package** — `refactor` — [#7](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/7) — move `PlotSqrt.hs`, `PlotInterest.hs`, `PlotUtils.hs` (exec 4)

### Liquidity / density (pre-existing) — exec 7–8

14. **Chunk × density EVM mul** — `feat` — [#10](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/10) (exec 8)

15. **Density → Panoptic `optionRatio` brainstorm** — `docs` — [#11](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/11) (exec 7)

### Hygiene — exec 5

16. **Commit / PR** scratchpad WIP — `chore` — [#12](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/12) (exec 5)
