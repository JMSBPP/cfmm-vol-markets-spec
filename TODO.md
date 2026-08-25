
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

**Execution order — objective: close the \(\lambda_{X/M}\) claim (README `MODEL_CLOSURE` §2), 2026-08-23.** Dependency order, not issue number:

| Step | Issue | Delivers for the claim | Gate |
|---|---|---|---|
| 1 | #35 (TODO 24) | \(\chi(\mathcal{LC})\) via per-tick CLMM identity | `CLMMPosition` witness test → Aristotle |
| 2 | #36 (TODO 25 `feat`) | four \(\mathcal{LC}_{\mathrm{leg}}\), \(\mathrm{or}(\mathrm{leg})\to L_{\mathrm{leg}}\) in Haskell | Hop B vs 4-leg sum |
| 3 | #34 (TODO 23) + TODO 19/20 | \(u\), atomic \([\nu_{\mathrm{arb}}/\nu]\), \(\sigma_{IV}=2\phi e^{u/2}\) | `volume_path.gms` golden table |
| 4 | #51 (TODO 26) | the claim: spec → ex-post LVR check → Aristotle statement | needs 1–3; Lean workspace (parent Phase 3) |
| 5 | #3 (TODO 7) | \(r^{\phi}=\phi\delta_{\mathrm{trans}}\) — fee side of §3 | after 3 |
| 6 | #31 (TODO 21 Slice 2) | \(r^e_{\mathrm{arb}}=\Lambda(\gamma(u-u^\star))\) — mixture weight | after 3 |
| 7 | #28 (TODO 22) | ex-ante price of the bracket — downgraded | after 6 |
| 8 | #2, #1, #5 (TODO 6, 5, 9) | expected-return composition, fee capture, stremia body | after 5 |
| 9 | #10, #11 (TODO 14, 15) | LDF / density generalization | parked |
| 10 | #6–#9, #12 | refactors / hygiene | parked |

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

19. **Exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\)** — `feat` — **split spine Lane B** (Option 3, 2026-08-23)
   - **MUST** keep this symbol / spelling in code, tests, issues, and docs
   - Type: `TransactionalReturn` (not `TransactionalExpectedReturn` — avoids conflating return with MEV \(r^{\phi}\) or fee price)
   - Evaluator: `runTransSwapAlongTenorMixture`; leg blend \(w\) documented as implementation device only
   - Orthogonal to directional price moves; volatility-measured (arbs not directional)
   - Cite MEV note for motivation only — **never** adopt its \(\Delta\pi_{\mathrm{trans}}\) naming
   - Lane A (\(\delta_{\mathrm{trans}}\), \(r^{\phi}=\phi\cdot\delta_{\mathrm{trans}}\)) is Slice 2 / #7; bridge \(r_{\mathrm{trans}}^{e}\leftrightarrow\delta^{\star}\) via #23 golden paths
   - Spec: `docs/superpowers/specs/2026-08-22-scratchpad-rarb-trans-flow-design.md` §1b, §2
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
   - **Definition pinned (README, 2026-08-23):** \(r_{\Delta Q_{\mathrm{arb}}}^{e}\equiv\Lambda(\gamma(u-u^{\star}(\sigma^{e})))=\Lambda(2\gamma\ln(\sigma_{IV}/\sigma^{e}))\), \(u^{\star}=2\ln(\sigma^{e}/2\phi)\); \(\Lambda\) = anchor sigmoid; \(\gamma\) free scale. Vol-gap channel (↑ in \(\phi\)); LVR band-crossing ↓ in \(\phi\) ⇒ \(\partial_{(r_{\mathrm{trans}}^{e},r_{\mathrm{arb}}^{e})}\) and \(1-\big[\nu_{\mathrm{trans}}/\nu\big]\) stay distinct
   - `feat`: `ImpliedVolatility`/`ExpectedVolatility` → \(u^{\star}\) → `volGap` → \(\Lambda\) (reuse `AdaptiveStremia` sigmoid); orthogonality lemma to Aristotle alongside #35
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
   - Derive \(\nu_{\mathrm{trans}}=\sum\sqrt{\bar p|\Delta Q_X\Delta Q_M|}\) from JSON `dQx`/`dQM`; \(\big[\nu_{\mathrm{trans}}/\nu\big]\) read as an atomic given value (not a computed ratio)
   - Golden table \(\big[\nu_{\mathrm{trans}}/\nu\big](\delta^\*,\kappa,\bar\phi,\ldots)\) from GAMS grid (`make test-gams`); option A (exogenous \(\nu\)) **pre-prover stub only**
   - Prereq for #7 \(\delta_{\mathrm{trans}}=\nu_{\mathrm{trans}}/\pi_{\mathrm{trans}}^{\Delta Q}\) beyond stub; complements RARB Slice 1 Lane B (#19 `TransactionalReturn`)
   - Reads: `refs/volume_path.gms`, `refs/VOLUME_PATH.md`, `refs/MEV_TAX_MODEL_ONE_NOTES.md`

24. **\(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\) decomposition** — `docs`→`feat` — [#35](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/35)
   - Spec: `docs/superpowers/specs/2026-08-22-scratchpad-pi-varphi-lvr-decomposition-design.md`
   - \(\pi^{c|p}+\pi^{\mathrm{RAN}}\equiv\pi^{\varphi}\) (CLMM); \(\pi^{\varphi}=\pi^{\phi}(\pi_{\mathrm{trans}}^{\Delta Q})-\pi^{\mathrm{LVR}}(\pi_{\mathrm{arb}}^{\Delta Q})\)
   - \(\pi^{\mathrm{arb}}\equiv\pi_{\mathrm{arb}}^{\Delta Q}\) (#21); LVR = normalized return read off arb leg; \(r^{\varphi}=r^{\phi}-r^{\mathrm{LVR}}\)
   - Depends: RARB trans tag (#19), arb mixture (#21); CLMM identity test vs `CLMMPosition`
   - **CLMM identity PROVED (2026-08-23):** \(\pi^{\varphi}(\mathrm{Id}_i[\mathcal{LC}];p)=\mathrm{amount}_0(\mathrm{Id}_i)\,[\pi^{c|p}+\pi^{\mathrm{RAN}}](p)\), \(r\) = sqrt-price ratio; normalization per \((i,\Delta_i)\) not per \(\Delta_i\). `CLMMPosition.fromChunk` (chunk-constructed, #27) + witness test. Remaining: \(\chi(\mathcal{LC})\) definition for #26; Aristotle transcription

25. **\(\pi^{\sigma}=f(\pi^{\varphi})\) — Panoptic/Haskell bridge (not MEV Σ)** — ~~`docs`~~→`feat` — [#36](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/36) / docs half merged [#38](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/38) (2026-08-23)
   - **Ground truth:** shipped Hop A/B — \(\pi^{\sigma}=\Delta Q_{v}\cdot\Pi^{\sigma}_{\mathrm{opt}}\) with
     \(\Pi^{\sigma}_{\mathrm{opt}}=N_{\mathrm{id}}\bigl((P-P^{\star})/P^{\star}-\ln(P/P^{\star})\bigr)+R\) (`VariancePortfolio` / `MintPlan` → `targetVegaFromMint`)
   - ~~**Open:** identify how \(\pi^{\varphi}\) enters \(\Pi_{\mathrm{opt}}\) / \(R\) / the book~~ **Pinned (README, #38):** \(\hat\pi^{\sigma}\equiv\sum_{k=0}^{3}[\pi^{\varphi}(\ell_k;p^\star)-\pi^{\varphi}(\ell_k;p)]\), \(\ell_k=(i_k^-,i_k^+,L_k)\), \(L_k=\Lambda(i_k^-,i_k^+;\mathrm{or}(k)\Delta Q_\upsilon)\); \(\pi^{\varphi}(\ell;p_{1/2})\) = Uniswap V3 position value. Hop A/B \(F-\mathrm{Log}\) = continuum-limit remark; MEV \(\sum L(i)\pi^{\varphi}(i)\) = short side, **not** ground truth
   - **`feat` (2026-08-24):** (a) ✓ `Panoptic.LegChunk.legChunks` — four \(\mathcal{LC}_{\mathrm{leg}}\) from the tokenId bits (≙ `PanopticMath.getLiquidityChunk`), envelope `mintChunk` kept as SFPM `positionSize`; (b) ✓ `legLiquidity` = \(\mathrm{or}(\mathrm{leg})\cdot\Delta Q_\upsilon\) inverted per token side; (d) ✓ via #27 (`fromChunk`); \(\hat\pi^\sigma\) = `Payoffs.VolatilityReplica.fourLegReplica`, plots `outputs/Payoffs/Replica/`; (c) ✓ (#28.1, PR #64) — continuous `lnQ96` removed the sawtooth; `panel-replica-vs-hopB.png` back; the normalized overlay is #28 Phase 1
   - Spec pointer: `cfmm-theory/docs/superpowers/specs/2026-08-19-scratchpad-target-vega-replication-design.md` (≡^R OPEN); roadmap roles doc
   - Depends: #24 (net \(\pi^{\varphi}\)); uses existing `VariancePortfolio` / `CLMMPosition`
   - Deliverable: ~~design note pinning \(f\) from Haskell~~ (#38); then code/tests (a)–(d)

26. **\(\lambda_{X/M}\) per-token LVR rate claim** — `docs`→`feat` — [#51](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/51)
   - README `MODEL_CLOSURE` §2: \(\lambda_{X/M}(u,\phi_{X/M};\mathcal{LC}_{\mathrm{leg}})\overset{?}{=}\phi_{X/M}(2e^{u/2}-1)^+\chi(\mathcal{LC}_{\mathrm{leg}})\); LVR = arb after-fee profit
   - Spec (define \(\chi\), derive/refute) → ex-post check (benchmark − `principal` along `TickPath`) → Aristotle statement with #35
   - Depends: #35, #36 feat, #34 (+19/20); proof gated on parent `.planning` Phase 3

27. **Fold `ChunkPrincipal` into `CLMMPosition` as a `Scale`** — `refactor` — [#54](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/54)
   - `chunkPrincipal` = \(\mathrm{amount}_0(\mathcal{LC})\cdot\) `CLMMPosition` (per-tick identity, #35) ⇒ `fromChunk`, `Scale = Unit | ByAmount0`, plot flag; amounts → `LiquidityChunk`; delete `Payoffs.ChunkPrincipal`
   - Precedes #36 (four \(\mathcal{LC}_{\mathrm{leg}}\) built on `fromChunk`)

28. **T1/T2 ladder replication of `VariancePortfolio` (Panoptic × LDF hybrid)** — `docs`→`fix`/`feat` — [#59](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/59)
   - Spec: `docs/superpowers/specs/2026-08-24-scratchpad-ladder-replication-design.md` (v3; Reality Checker + Solidity SC Engineer ×2)
   - T0 continuum → T1 geometric ladder \(\ell(\xi^\star,\iota;x)\) (fixed benchmark, Bunni-realizable) → T2 4-leg via \(\mathcal{B}\) on token1 notional (`asset = 1` all legs); knobs \(\theta_{\mathrm{LDF}}=(\xi_P,\xi_C,\omega)\); norm B, C later
   - Sub-issues: **0 ✓** [#61](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/61)/PR #62 (asset = 1 all legs, integerSqrt strike, mulDiv staged forms, `docs/BITWIDTHS.md`); **1 ✓** [#63](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/63)/PR #64 (`lnQ96`); **2 ✓** `Payoffs.LadderPosition` (T1; regressions of Thm 7(i)/9/10, Prop 1; T1/N_1 vs c(4000)·logPortfolio 2.8e-6); **3 ✓** `Panoptic.Binning` + `replicaError` (Cor 1/Thm 8 regressions; \(e^\sigma_W(\mathcal B)=2.1\)e-4 at S=4000, \(\approx S^2\) sweep; or = (127,…) = equal notional per leg, Cor 4); **4 ✓** README § REPLICATION_THEORY — **#28 complete** except the peer follow-ons (O(Δi) bound, off-midpoint strike, χ via Thm 5)
   - Supersedes TODO #25 (c) (Hop B comparison) via Item 1

29. **Single T0 definition; `VariancePortfolio` = reference only** — `refactor` — [#77](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/77)
   - `logPortfolioQ96` moves to `Payoffs.Log`; `VariancePortfolio.fromDef6` = \(N_{\mathrm{id}}\cdot\)`logPortfolioQ96` + R, `fromLegs` delegates; module labelled T0 reference; `panel-replica-vs-hopB` retired (superseded by t1-vs-t0 / t2-vs-t1)

30. **Path accrual — fees and LVR per chunk along a tagged tick path; comparative statics** — `feat` — [#79](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/79)
   - `Payoffs.PathAccrual`: per-step amounts moved (Uniswap), fee on the token paid in, LVR on arb steps = concavity gap (Thm 5); split fees_trans/fees_arb/LVR_gross; LVR_net = LVR_gross − fees_arb; \(\pi^{\varphi}\) = fees_trans − LVR_net
   - Synthetic tagged path (LCG + Bresenham share); 4-leg roll-up; panels vs \([\nu_{\mathrm{arb}}/\nu]\) and vs step size; prover path replaces it in #34

31. **Price-update transfer \(s\) replaces \(\tau_{\mathrm{MEV}}\); arbs as delta-hedgers; #34 re-scoped** — `docs` — [#82](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/82)
32. **Delta-hedge rebate: holder-hedged replication supersedes the signed transfer \(s\) (Defs 12–14, Prop B); #34 re-scoped into trans / holder-hedge / residual-arb** — `docs` — [#84](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/issues/84) / [#85](https://github.com/JMSBPP/cfmm-volInstrumentsFormal/pull/85) — `docs/superpowers/specs/2026-08-25-scratchpad-delta-hedge-rebate-design.md`
   - Note: `docs/superpowers/specs/2026-08-25-scratchpad-price-update-transfer-design.md` — Prop A (roles), Defs 9–11 (signed \(s\), budget, equilibrium \(\mathrm{LVR}_{\mathrm{net}}=s^\star\nu_{\mathrm{arb}}\)), two-source path (GAMS round trips + external update rule)
   - #34 becomes: trans half = GAMS replay (given \([\nu_{\mathrm{trans}}/\nu]\), \(u\)); arb half = \(P_{\mathrm{ext}}\) + rule at \(s\) (\([\nu_{\mathrm{arb}}/\nu]\) as output). Implementation item next.

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
