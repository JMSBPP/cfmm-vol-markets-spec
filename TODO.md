
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

6. ~~**`MarkUpStructure` superclass; `FeeStructure` as instance**~~ — `feat` — [#4](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/4) / [#17](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/17)
   - `Pricing.MarkUpStructure` + `TwoSidedMarkUp`; Swap / `ReturnFromKappa` / capture migrate to polymorphic markup; survival `toFeePips` unchanged

---

## Open

**Role roadmap (read first):** `docs/superpowers/specs/2026-08-22-scratchpad-channel-roles-roadmap.md`  
— Lane A = trans targets via GAMS path utilities (\(\Delta Q,\Delta s\) transient); Lane B = arb via vol-spread; Lane C = \(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\). Issue numbers ≠ execution priority.

Workflow: see `AGENTS.md` / `CLAUDE.md` / `QWEN.md` (classify → branch → issue → PR → cross-comment).

| TODO | Type | Issue | PR | Status |
|------|------|-------|-----|--------|
| 6 | `feat` | [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2) | [#15](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/15) | **blocked** (prereqs 17–21) |
| 7 | `feat` | [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3) | [#16](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/16) | open |
| 9 | `feat` | [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) | [#18](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/18) | open |
| 10 | `refactor` | [#6](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/6) | [#19](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/19) | open |
| 11 | `refactor` | [#7](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/7) | [#20](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/20) | open |
| 12 | `refactor` | [#8](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/8) | [#21](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/21) | open |
| 13 | `refactor` | [#9](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/9) | [#22](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/22) | open |
| 14 | `feat` | [#10](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/10) | [#23](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/23) | open |
| 15 | `docs` | [#11](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/11) | [#24](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/24) | open |
| 16 | `chore` | [#12](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/12) | [#13](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/13) | open |
| 17 | `feat` | — | — | open (no GitHub issue yet) |
| 18 | `feat` | — | — | open (no GitHub issue yet) |
| 19 | `feat` | — | — | open (no GitHub issue yet) |
| 20 | `feat` | — | — | open (no GitHub issue yet) |
| 21 | `docs`→`feat` | [#31](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/31) | [#33](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/33) | open — **Slice 1 merged**; Slice 2+ remain |
| 22 | `docs` | [#28](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/28) | — | open |
| 23 | `feat` | [#34](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/34) | — | open |
| 24 | `docs`→`feat` | [#35](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/35) | — | open |
| 25 | `docs`→`feat` | [#36](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/36) | — | open |

### Pricing / returns / fee-revenue

6. **`ExpectedReturn` composition / nonzero \(r(0)\)** — `feat` — [#2](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/2) / [#15](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/15) — **BLOCKED / deferred**
   - Parked until measure / expectation / return-split prereqs (**#17–#21**) exist
   - Then: `ExpectedReturn <>` Realized (and other expecteds) → that sum *is* future \(r(0)\) before κ-scaling
   - FeePips path today is through-origin (\(r=\kappa\phi\)); VISIBLE NOTE in `Pricing.ExpectedReturn`
   - Do **not** implement #6 while brainstorming #17–#21

7. **Ref transactional return** \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) — `feat` — [#3](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/3)
   - Distinct from payoff \(\pi^\phi\); scope in `refs/VOLATILITY_INTRUMENTS_MEV.md`
   - Decide: scalar control return type vs leave in notes only
   - **Notation:** keep scratchpad \(r^\phi\) / \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) language; do **not** adopt MEV-doc \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) labels (wrong)

9. **`AdaptiveStremia` body** — `feat` — [#5](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/5) — still stub \(\phi(\Theta_\phi;\sigma^2,\nu)\)

Yes, those issues matches the intention, but the numbered order that is as it is right now does not imply the hierarchy of importance and the hierarchy of importance is now defined as follows. We are choosing to implement the issues as they have less like semantic impact. For example, renames are less semantically impactful because for example, the fee structure to mark up structure is just refactoring code. And then we start like imposing an order of execution of the issues based on that
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

17. **`DiscountFactor` / measure \(m(\cdot)\)** — `feat`
   - Parametric type (README: `DiscountFactor.hs`); indexes \(\Delta Q\) and/or \(\phi\)
   - Feeds \(\mathbb E[m\cdot\pi]\) for swap and fee-revenue expected returns
   - No GitHub issue until this TODO is accepted / brainstormed

18. **`Expectation` constructor types** — `feat`
   - Typed \(\mathbb E[m\cdot\pi]\) object (not only hand-built mixture weights)
   - Depends on #17
   - No GitHub issue yet

19. **Exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\)** — `feat`
   - **MUST** keep this symbol / spelling in code, tests, issues, and docs
   - Orthogonal to directional price moves; volatility-measured (arbs not directional)
   - Cite MEV note for motivation only — **never** adopt its \(\Delta\pi_{\mathrm{trans}}\) naming
   - Decide: first-class return type vs notes-only scalar control
   - No GitHub issue yet

20. **\(\sigma_{IV}\) stand-in** — `feat`
   - Latent \(u=\ln(V/L)\); read \(\sigma_{\mathrm{IV}}=2\phi e^{u/2}\); T0 calibration pin from \((\sigma_X,\phi)\)
   - Spec: `docs/superpowers/specs/2026-08-22-scratchpad-sigma-iv-latent-u-design.md`
   - Module `Volatility.ImpliedVolatility` (T0); T1 observer / T2 u88 deferred
   - No GitHub issue yet (open when plan approved)

21. **Parametric \(r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})\)** — `docs` then `feat` — [#31](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/31) / [#33](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/33)
   - \(\sigma^{e}\) = risk-neutral expectation of realized vol (`ExpectedVolatility` + `VolHorizon`: WINDOW \| tenor); spec `docs/superpowers/specs/2026-08-22-scratchpad-expected-volatility-design.md`
   - **Slice 1 merged (PR #33):** `ExpectedVolatility` uniform tenor + window stub, minimal `ImpliedVolatility`, `volGap`
   - Remaining: Slice 2+; arb gap \(g(\cdot)\); full \(\mathbb{E}^{\mathbb{Q}}\) via #17–#18
   - Depends on #20; **#22** (\(\beta\)) before compose

22. **Understand \(\beta\) in the \(r_{\Delta Q}^{e}\) affine split** — `docs` — [#28](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/28)
   - Canonical split (README): \(r_{\Delta Q}^{e}=r_{\Delta Q_{\mathrm{trans}}}^{e}+\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})\)
   - **Disambiguate** \(\beta\) from other repo uses: CES \(\beta=\eta\) (CPMM elasticity), AdaptiveStremia/MEV \(\beta_j\) (logistic centers) — not the same symbol economically
   - Brainstorm: what object is \(\beta\) (scalar weight? pool parameter? function of \(\kappa\)/\(\phi\)/liquidity?); units; bounds; who sets it; relation to measure \(m(\cdot)\) and \(\mathbb E[m\cdot\pi]\)
   - Deliverable: short design note (spec in `docs/superpowers/specs/`) before #21 implement; may stay notes-only if no code twin warranted this cycle
   - Prereq for composing full \(r_{\Delta Q}^{e}\) and unblocking #6

23. **\(\nu_{\mathrm{trans}}\) from `volume_path.gms` (prover-native \(u\leftrightarrow\nu\))** — `feat` — [#34](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/34)
   - Spec: `docs/superpowers/specs/2026-08-22-scratchpad-rarb-trans-flow-design.md` §3 (option **B** approved)
   - Shock: \(V=\bar L e^u\), \(\delta^\*\) → `volTgtWad`, `txlVolumeRate`; \(u=\ln(V/\bar L)=\ln\kappa\) at prover boundary
   - Derive \(\nu_{\mathrm{trans}}=\sum\sqrt{\bar p|\Delta Q_X\Delta Q_M|}\) from JSON `dQx`/`dQM`; \(g=\nu_{\mathrm{trans}}/V\)
   - Golden table \(g(\delta^\*,\kappa,\bar\phi,\ldots)\) from GAMS grid (`make test-gams`); option A (exogenous \(\nu\)) **pre-prover stub only**
   - Prereq for #7 \(\delta_{\mathrm{trans}}=\nu_{\mathrm{trans}}/\pi_{\mathrm{trans}}^{\Delta Q}\) beyond stub; complements RARB Slice 1 (#19 trans tag)
   - Reads: `refs/volume_path.gms`, `refs/VOLUME_PATH.md`, `refs/MEV_TAX_MODEL_ONE_NOTES.md`

24. **\(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\) decomposition** — `docs`→`feat` — [#35](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/35)
   - Spec: `docs/superpowers/specs/2026-08-22-scratchpad-pi-varphi-lvr-decomposition-design.md`
   - \(\pi^{c|p}+\pi^{\mathrm{RAN}}\equiv\pi^{\varphi}\) (CLMM); \(\pi^{\varphi}=\pi^{\phi}(\pi_{\mathrm{trans}}^{\Delta Q})-\pi^{\mathrm{LVR}}(\pi_{\mathrm{arb}}^{\Delta Q})\)
   - \(\pi^{\mathrm{arb}}\equiv\pi_{\mathrm{arb}}^{\Delta Q}\) (#21); LVR = normalized return read off arb leg; \(r^{\varphi}=r^{\phi}-r^{\mathrm{LVR}}\)
   - Depends: RARB trans tag (#19), arb mixture (#21); CLMM identity test vs `CLMMPosition`

25. **\(\pi^{\sigma}=f(\pi^{\varphi})\) — Panoptic/Haskell bridge (not MEV Σ)** — `docs`→`feat` — [#36](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/36)
   - **Ground truth:** shipped Hop A/B — \(\pi^{\sigma}=\Delta Q_{v}\cdot\Pi^{\sigma}_{\mathrm{opt}}\) with
     \(\Pi^{\sigma}_{\mathrm{opt}}=N_{\mathrm{id}}\bigl((P-P^{\star})/P^{\star}-\ln(P/P^{\star})\bigr)+R\) (`VariancePortfolio` / `MintPlan` → `targetVegaFromMint`)
   - **Open:** identify how \(\pi^{\varphi}\) (CLMM / fee−LVR, #24) enters \(\Pi_{\mathrm{opt}}\) / \(R\) / the book — board claim \(\pi^{\sigma}=f(\pi^{\varphi})\); MEV \(\sum L(i)\pi^{\varphi}(i)\) is **not** ground truth
   - Spec pointer: `cfmm-theory/docs/superpowers/specs/2026-08-19-scratchpad-target-vega-replication-design.md` (≡^R OPEN); roadmap roles doc
   - Depends: #24 (net \(\pi^{\varphi}\)); uses existing `VariancePortfolio` / `CLMMPosition`
   - Deliverable: design note pinning \(f\) from Haskell; then code/tests if warranted

Later (not opened yet): compose \(r_{\Delta Q}^{e}\) from #19+#21; wire into parametrized \(\pi^{\Delta Q}/\pi^{\phi}\); then unblock #6.

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
