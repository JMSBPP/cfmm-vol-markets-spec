# Scratchpad RARB transactional flow — design

**Status:** approved §1–§3 — plan TBD; TODO #7, #19, **#23** (\(\nu\) from `volume_path.gms`, **blocked** — prover refs removed from this repo 2026-09-01)  
**Date:** 2026-08-22  
**Repo:** `cfmm-theory` / package `scratchpad/`  
**Brainstorm:** RARB split → orthogonally parametrized payoffs; trans leg exogenous; **prover-native** \(u\leftrightarrow\nu\) via `volume_path.gms` (now in `cfmm-numopt`, not this repo)  
**Linked TODO:** #7, #19, **#23**, #17–#18 (measure), #20 (\(u=\ln(V/L)\)), #21–#22 (arb leg, \(\beta\))

**Reads:** `scratchpad/README.md` (RARB block); `Payoffs/Swap.hs`; `Pricing/ExpectedReturn.hs`; `docs/superpowers/specs/2026-08-22-scratchpad-sigma-iv-latent-u-design.md`; ~~`refs/MEV_TAX_MODEL_ONE_NOTES.md`~~; ~~`refs/VOLATILITY_INTRUMENTS_MEV.md`~~; ~~`refs/VOLUME_PATH.md`~~; ~~`refs/volume_path.gms`~~ (removed — use `cfmm-numopt/model/mev_tax_model_one/`)

---

## Purpose

Wire the **expected-return split (RARB)** to **orthogonally parametrized payoffs**:

1. Transactional swap flow \(\pi_{\mathrm{trans}}^{\Delta Q}\) uses **only** exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) as control (approach **B**: tagged return type).
2. Arb swap flow is a **separate** parametrization path (deferred: #21 + \(\beta\) #22).
3. Latent **volume state** connects scratchpad \(u=\ln(V/L)\) (#20) with MEV **\(\nu\)** (volume-dimensional utilization) so \(\delta_{\mathrm{trans}}\) and \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) (#7) align with existing MEV / volume-path results.

**Out of scope this spec:** full `DiscountFactor` (#17), composed \(\pi^{\Delta Q}\) (#6 unblock), arb leg implementation, on-chain packing, AdaptiveStremia \(\phi(\Theta;\sigma^2,\nu)\) body (#5).

---

## §1 — RARB data flow (approved)

Canonical split (scratchpad notation — **required**):

\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{\mathrm{IV}},\sigma^{e}).
\]

| Channel | Control | Parametrized object | Cycle |
|---------|---------|---------------------|-------|
| Fee revenue | \(r_\phi^e\) | \(\pi^\phi(r_\phi^e)\) | **shipped** |
| Swap (trans) | \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) **exogenous** | \(\pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e})\) | **this spec** |
| Swap (arb) | \(r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})\) | \(\pi_{\mathrm{arb}}^{\Delta Q}\) | deferred |
| Swap (full) | composed \(r_{\Delta Q}^{e}\) | \(\pi^{\Delta Q}\) affine sum | deferred (#6) |

**Orthogonality rule:** code that builds transactional swap flow must **not** accept arb controls (\(\sigma_{\mathrm{IV}}\), \(\sigma^{e}\), \(\beta\), `volGap`). Only `TransactionalExpectedReturn`.

**Planned composition (payoff level, later):**

\[
\pi^{\Delta Q}
=
\pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e})
+
\beta\cdot\pi_{\mathrm{arb}}^{\Delta Q}\bigl(r_{\mathrm{arb}}^{e}\bigr).
\]

Mirrors RARB at the return level; **not** a single mixture weight on one undifferentiated swap.

---

## §2 — Approach B: tagged transactional expected return (approved)

### Newtypes

| Haskell (planned) | Math | Role |
|-------------------|------|------|
| `TransactionalExpectedReturn` | \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) | Exogenous scalar control (#19); **only** input to trans swap mixture |
| `ExpectedReturn` (existing) | \(r_\phi^e\), generic fee/swap shortcuts | Unchanged this cycle |
| `ArbExpectedReturn` (deferred) | \(r_{\Delta Q_{\mathrm{arb}}}^{e}\) | From `volGap` + \(g\) (#21) |
| `ComposedExpectedReturn` (deferred) | full RARB sum | #6 unblock |

`TransactionalExpectedReturn` wraps `FeePips` (same Q96 mixture mechanics as `ExpectedReturn`) but is **not** interchangeable at call sites — prevents passing composed \(r_{\Delta Q}^{e}\) into the trans path.

### API (Slice 1)

```haskell
-- Pricing.TransactionalExpectedReturn
newtype TransactionalExpectedReturn = TransactionalExpectedReturn FeePips

transactionalExpectedReturnWeightX96 :: TransactionalExpectedReturn -> Integer

-- Payoffs.Swap (or Payoffs.TransSwap if file splits)
runTransSwapAlongTenorMixture
  :: InterestPriceMap
  -> TransactionalExpectedReturn
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
  -> InterestTick
  -> PayoffX96
```

Mechanics: identical to `runSwapAlongTenorMixture` / `expectedReturnWeightX96`, but weight sourced from `TransactionalExpectedReturn` only.

### Tests (Slice 1)

- Trans mixture with weight 0 / 1 / interior matches pay-only / recv-only / blend (mirror existing swap mixture tests).
- Type-level story documented: trans runner has no `ImpliedVolatility` / `ExpectedVolatility` / arb parameters in signature.

---

## §3 — Prover-native \(u\leftrightarrow\nu\) (option **B**, approved)

### Canonical coupling: `volume_path.gms` shock vector

The scratchpad **does not** treat \(\nu_{\mathrm{trans}}\) as an independent exogenous input (option A is **pre-prover stub only**). The canonical contract matches `refs/volume_path.gms`:

| GAMS input | Math | Scratchpad |
|------------|------|------------|
| `volTgtWad` | \(V=\sum|\Delta Q_X|\) | \(V=L\,e^u\) (#20) |
| `liquidityRaw` | \(\bar L\) | `TickLiquidity` |
| `txlVolumeRate` | \(\delta^\*\) | target transactional rate |
| `kappa = volTgt/Lbar` | \(V/\bar L\) | **\(e^u\)** — so \(u=\ln\kappa=\ln(V/\bar L)\) at the prover boundary |

Prover **outputs** certify `deltaRealized`, `rPhiRealized`, `dQx[]`, `dQM[]`. Post-process:

\[
\nu_{\mathrm{trans}}=\sum_j\sqrt{\bar p\,|\Delta Q_X(j)\,\Delta Q_M(j)|},
\qquad
\bar\pi=\sum_j\bigl(\bar p|\Delta Q_X|+|\Delta Q_M|\bigr),
\qquad
g\equiv\frac{\nu_{\mathrm{trans}}}{V}.
\]

**Shock workflow (bridge / differential test):**

1. T0 IV pin: \(u\leftarrow u^\star(\sigma_X,\phi)\) **or** shock-driven \(u=\ln(\texttt{volTgtWad}/\bar L)\).
2. Set \(V=\bar L\,e^u\) → `volTgtWad`; set \(\delta^\*\) → `txlVolumeRate`; pool → `sqrtPriceX96`, `liquidityRaw`, fees.
3. Run `volume_path.gms`; abort if precheck fails (half-ellipse, \(\kappa\) floor — see `VOLUME_PATH.md` §1).
4. From JSON: compute \(\nu_{\mathrm{trans}}\), \(g=\nu_{\mathrm{trans}}/V\); assert \(\nu_{\mathrm{trans}}/\bar\pi\approx\delta^\*\).

### Derived \(\nu_{\mathrm{trans}}\) off JSON (golden \(g\))

When JSON is unavailable (along-tenor estimates, unit tests without GAMS):

\[
\nu_{\mathrm{trans}}(N)=V(N)\,g(\delta^\*,\kappa,\bar p,\bar\phi_X,\bar\phi_M,N),
\qquad
V=\bar L\,e^u,
\qquad
\kappa=V/\bar L.
\]

**Finding \(g\):** grid `volume_path.gms` over feasible \((\delta^\*,\kappa,\phi_X,\phi_M,N)\); tabulate \(g=\nu_{\mathrm{trans}}/V\) from each converged solve (`make test-gams` / golden JSON). Uniform-step closed form \(g\approx\delta^\*\,\bar p/(1-x(\delta^\*))\) is **doc approximation only** — prover table wins when they differ (small \(\kappa\) regime).

**Pre-prover stub (option A, temporary):** `NuTrans` as caller-supplied scalar in Slice 2 **must** be labeled pre-prover; default target is replay/table from §3. Do **not** treat exogenous \(\nu\) and IV-pinned \(u\) as jointly valid without GAMS feasibility.

### MEV references (economics + dynamics)

- Cumulative \(\nu_{\mathrm{trans}}\), \(\delta_{\mathrm{trans}}^{\mathrm{MEV}}=\nu_{\mathrm{trans}}/\bar\pi\): `MEV_TAX_MODEL_ONE_NOTES.md`.
- Event-time \(\nu(t)\), \(\partial\nu/\partial t\): `VOLATILITY_INTRUMENTS_MEV.md` (Theorem 36).
- Scratchpad **does not** import MEV \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) labels (#7).

### \(\pi_{\mathrm{trans}}^{\Delta Q}\) and \(\delta_{\mathrm{trans}}\)

**Transactional swap payoff (parametrized):**

\[
\pi_{\mathrm{trans}}^{\Delta Q}(t)
\;\equiv\;
\mathtt{runTransSwapAlongTenorMixture}\bigl(\mathrm{ipm},\, r_{\mathrm{trans}}^{e},\, \mathrm{swap},\, t\bigr).
\]

**Transactional rate (scratchpad pin — revised numerator):**

\[
\delta_{\mathrm{trans}}(t)
\;\equiv\;
\frac{\nu_{\mathrm{trans}}(t)}{\pi_{\mathrm{trans}}^{\Delta Q}(t)}.
\]

- Numerator **\(\nu_{\mathrm{trans}}\)** (volume-dimensional, latent, MEV-linked dynamics) replaces the draft README numerator \(u(t)\) alone.
- Denominator **\(\pi_{\mathrm{trans}}^{\Delta Q}\)** is the trans-only parametrized swap payoff — not MEV \(\bar\pi\), but **homogeneous** so the ratio is a **rate** suitable for \(r^\phi=\phi\,\delta_{\mathrm{trans}}\).

**Connection to MEV economics (citation only for volume share):**

\[
\delta_{\mathrm{trans}}^{\mathrm{MEV}}
=
\frac{\nu_{\mathrm{trans}}}{\bar\pi}
\]

recovered when \(\pi_{\mathrm{trans}}^{\Delta Q}\) aligns with the MEV linear-flow denominator \(\bar\pi\) along a certified volume path. Scratchpad keeps MEV \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) labels **out** of code (#7); cite `refs/` for motivation.

**Fee return link (#7, Slice 2):**

\[
r^{\phi}=\phi\cdot\delta_{\mathrm{trans}},
\qquad
r_\phi^e \;\text{eventually}\; \mathbb E[m(\phi)\cdot\pi^\phi]
\;\text{with trans control from}\;
\delta_{\mathrm{trans}}.
\]

Distinct from payoff \(\pi^\phi\) (already shipped).

### \(u\) still enters arb leg, not trans parametrization

- Trans leg parametrization: **only** \(r_{\Delta Q_{\mathrm{trans}}}^{e}\).
- \(u\) / \(\nu\) enter **rates** (\(\delta_{\mathrm{trans}}\), \(\sigma_{\mathrm{IV}}\)) and **arb** leg (#21), not the trans mixture weight.

---

## §4 — Module map and slices

| Slice | Deliverable | Depends |
|-------|-------------|---------|
| **1** | `TransactionalExpectedReturn`, `runTransSwapAlongTenorMixture`, tests | — |
| **2** | \(\delta_{\mathrm{trans}}=\nu_{\mathrm{trans}}/\pi_{\mathrm{trans}}^{\Delta Q}\); \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) stub; pre-prover `NuTrans` optional | Slice 1, #20 T0 |
| **3** | **#23:** JSON replay \(\nu_{\mathrm{trans}}\) from `dQx`/`dQM`; golden \(g\) table from `volume_path.gms`; \(u=\ln\kappa\) shock helper | `refs/volume_path.gms`, Slice 2 |
| **4** | T1 observer; `tenorTickPath` vs prover path consistency | #20 T1 |
| **5** | `ArbExpectedReturn`, compose \(\pi^{\Delta Q}\), full RARB | #17–#18, #21, #22 |

**Files (Slice 1):**

- `src/Pricing/TransactionalExpectedReturn.hs`
- `src/Payoffs/Swap.hs` — add `runTransSwapAlongTenorMixture`
- `test/Spec.hs`
- `README.md` — replace WIP prose with spec pointer; **preserve** user RARB / \(\delta_{\mathrm{trans}}\) block; fix numerator \(u\to\nu_{\mathrm{trans}}\) when approved

---

## §5 — Symbol hygiene

| Symbol | Meaning | Not |
|--------|---------|-----|
| \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) | Exogenous trans expected return | MEV \(\Delta\pi/\pi\) |
| \(\pi_{\mathrm{trans}}^{\Delta Q}\) | Parametrized trans swap payoff | Full \(\pi^{\Delta Q}\) |
| \(u\) | \(\ln(V/L)\) | Mixture weight |
| \(\nu\), \(\nu_{\mathrm{trans}}\) | Volume-dimensional utilization / cumulative trans flow | Fee-mix \(\kappa\) |
| \(\delta_{\mathrm{trans}}\) | \(\nu_{\mathrm{trans}}/\pi_{\mathrm{trans}}^{\Delta Q}\) (scratchpad) | Raw \(u/\pi\) without \(\nu\) bridge |
| \(\beta\) | RARB arb weight (#22) | CES \(\beta=\eta\), logistic \(\beta_j\) |

---

## §6 — Economic meaning

In a Uniswap-style pool with latent nominal volume \(V\) and observed liquidity \(L\):

- **Transactional traders** face swap payoffs parametrized by an **exogenous** expected return \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) — the LP does not infer this from arb vol gaps; it is a control / market input (#19).
- **Arbitrageurs** (later) face a **different** parametrization driven by \(\sigma_{\mathrm{IV}}-\sigma^{e}\) — orthogonal to trans flow in RARB.
- **\(\nu_{\mathrm{trans}}\)** is the effective transactional volume accumulated along the tenor (MEV geometric-flow measure); linking it to \(u=\ln(V/L)\) ties **fee/market IV state** to **flow utilization dynamics** already analyzed in the MEV tax model.
- **\(\delta_{\mathrm{trans}}\)** is the ratio of latent trans volume intensity to the parametrized trans swap payoff — the scalar that scales **fee return** \(r^\phi=\phi\,\delta_{\mathrm{trans}}\) without conflating fee payoff \(\pi^\phi\).

---

## §7 — Testing

| Test | Slice |
|------|-------|
| Trans mixture weights 0 / 1 / interior | 1 |
| Trans API has no arb/vol parameters in type | 1 |
| \(\delta_{\mathrm{trans}}\) dimensionless rate from stub \(\nu_{\mathrm{trans}}\), evaluated \(\pi_{\mathrm{trans}}^{\Delta Q}\) | 2 |
| \(r^\phi=\phi\cdot\delta_{\mathrm{trans}}\) FeePips round-trip | 2 |
| JSON replay: \(\nu_{\mathrm{trans}}\), \(g\) vs fixture `volume_path.json` | 3 |
| Golden \(g(\delta^\*,\kappa,\phi)\) within tol of GAMS grid | 3 |
| T0: \(V=L e^u\) ↔ `volTgtWad`/`liquidityRaw` shock encoding | 3 |

---

## §8 — README delta (when spec approved)

Replace draft numerator in user RARB block:

```diff
- \delta_{\text{trans}} (t) \equiv u(t) / \pi_{\text{trans}}^{\Delta Q}
+ \delta_{\text{trans}} (t) \equiv \nu_{\text{trans}}(t) / \pi_{\text{trans}}^{\Delta Q}(t)
+ \quad\text{with}\quad V(t)=L(i(t))\,e^{u(t)},\; u=\ln(V/L)\;\text{(#20)}.
```

Add spec link; keep `(RARB)` tag and user prose.

---

## Self-review (inline)

- [x] No TBD placeholders in core Slice 1–2 requirements
- [x] Orthogonality: trans parametrization excludes arb inputs — explicit
- [x] MEV \(\delta_{\mathrm{trans}}=\nu_{\mathrm{trans}}/\bar\pi\) cited as economics limit, not wrong scratchpad labels
- [x] Prover-native B coupling; option A pre-prover stub only
- [x] \(u=\ln\kappa\) at GAMS boundary; \(g\) from golden replay not hand-waved
- [x] Scope bounded: Slice 1 is trans tag + mixture only
- [x] Consistent with shipped `runSwapAlongTenorMixture` / `feeRevenueExpectedReturn` pattern
