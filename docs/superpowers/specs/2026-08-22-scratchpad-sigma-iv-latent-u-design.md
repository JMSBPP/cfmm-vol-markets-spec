# Scratchpad σ_IV without V(t) — latent u = ln(V/L) design

**Status:** draft — awaiting user review (plan TBD; TODO #20)  
**Date:** 2026-08-22  
**Repo:** `cfmm-theory` / package `scratchpad/`  
**Brainstorm:** README mathematical validity audit; A ≡ B (Kristensen recovery = explicit latent state)  
**Linked TODO:** #20 (σ_IV stand-in); prereqs #21 (r_arb^e), #22 (β), #17–#18 (measure)

**Reads:** `scratchpad/README.md` (expected-return split); `cfmm-options/IMPLIED_VOLATILITY.md`; `cfmm-discrete/STREAMING_PREMIUM.md` (Kristensen Eq 3.16); `Liquidity/TickLiquidity.hs`; `Volatility/TickVolatility.hs`; `Trading/KappaCoordinate.hs`

---

## Purpose

Pin **mathematically valid** implied-volatility algebra when nominal volume \(V(t)\) is unobserved. Recover Kristensen \(\sigma_{\mathrm{IV}}=2\phi\sqrt{V/L}\) by introducing latent \(u(t):=\ln(V(t)/L(i(t)))\), not by invalid log-difference approximations in the README WIP block.

**Out of scope this spec:** `DiscountFactor` / measure \(m(\cdot)\) (#17), full \(g(\sigma_{\mathrm{IV}}-\sigma^{e})\) (#21), β weight (#22), on-chain u88 packing implementation (#20 T2 code). See `docs/superpowers/specs/2026-08-22-scratchpad-expected-volatility-design.md` for \(\sigma^{e}\).

---

## §1 — Unified object (Kristensen = latent state)

### Canonical read map

\[
\sigma_{\mathrm{IV}}(t)
=
2\,\phi(\,;\sigma_X(t))\,\sqrt{\frac{V(t)}{L(i(t))}}
=
2\,\phi(\,;\sigma_X(t))\,\exp\!\Big(\tfrac{u(t)}{2}\Big),
\qquad
u(t) := \ln\!\Big(\frac{V(t)}{L(i(t))}\Big).
\]

### Fair-fee calibration (equilibrium only)

From Kristensen Eq 3.16 / `STREAMING_PREMIUM.md`, with **total** fee \(\phi=\bar\phi^\star+\phi_\Zeta\):

\[
\sigma_X(t)=\sigma_{\mathrm{IV}}(t)
=
2\,\phi(\,;\sigma_X(t))\sqrt{\frac{V(t)}{L(i(t))}}
\iff
u^\star(t)=2\ln\!\Big(\frac{\sigma_X(t)}{2\,\phi(\,;\sigma_X(t))}\Big).
\]

At pin: \(\sigma_{\mathrm{IV}}=\sigma_X\). This is an **equilibrium identity**, not identification of \(V\) from \(L\) alone off-equilibrium.

### Invalid README forms (rejected)

| Invalid | Why |
|---------|-----|
| \(\sigma_{\mathrm{IV}}\approx 2\phi[\ln V-\ln L]\) | Confuses \(u\) with \(\sigma_{\mathrm{IV}}\); correct link is \(2\phi e^{u/2}\) |
| \(\partial\sigma_{\mathrm{IV}}\sim 2\phi[\hat\epsilon_{V/L}/L-\kappa/L]\) | Dimensional error; \(\hat\epsilon_{V/L}\) is dimensionless |
| Fee-mix \(\kappa\) = liquidity growth \(\partial\ln L(i(t))/\partial\ln L(i(t-1))\) | Symbol collision with `KappaCoordinate` |

First-order expansion **only** around \(V/L\approx 1\):

\[
2\phi\,e^{u/2}\approx 2\phi\Big(1+\tfrac{u}{2}\Big),\qquad |u|\ll 1.
\]

---

## §2 — State update tiers

All tiers use the same read map \(\sigma_{\mathrm{IV}}=2\phi\,e^{u/2}\).

| Tier | Name | Update | Use |
|------|------|--------|-----|
| **T0** | Calibration pin | \(u\leftarrow u^\star(\sigma_X,\phi)\) | Default; valid at fair fee |
| **T1** | Tenor observer | \(\Delta u\approx(\hat\epsilon_{V/L}-1)\,\Delta\ln L\) accumulated | Off-equilibrium path |
| **T2** | u88 packing | Same \(u\) stored as packed integer | EVM storage; decode explicit |

**T0 observables (scratchpad today):** \(\sigma_X\) from Algebra-style window / `VolatilityAverage`; \(\phi\) from fee bag; \(L\) from `TickLiquidity`.

**T1 notes:** \(\hat\epsilon_{V/L}\) is an **observer** (fee revenue/L proxy or fitted), not raw \(\partial\ln V/\partial\ln L\) until \(V\) exists. Liquidity growth along tenor is **\(\kappa_L\)**, not fee-mix \(\kappa\).

**T2 notes:** u88 is width for \(u\), not plank `vol<<96` sqrt-price placement.

### Symbol hygiene

| Symbol | Meaning | Code |
|--------|---------|------|
| \(\sigma_{\mathrm{IV}}\) | Kristensen implied vol | `Volatility.ImpliedVolatility` (planned) |
| \(\sigma_X\) | Realized window vol | Oracle / `VolatilityAverage` |
| \(u\) | \(\ln(V/L)\) latent | `LogVolLiquidityRatio` |
| \(\kappa\) | Fee-mix on \([0,1]\) | `KappaCoordinate`, `kappaAt` |
| \(\kappa_L\) | Liquidity growth along tenor | `LiquidityGrowth` (T1, deferred) |
| \(\beta\) | Weight on arb return leg | TODO #22 (unrelated to CES \(\beta=\eta\)) |

### Feed into return split

\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{\mathrm{IV}},\sigma^{e}),
\qquad
r_{\Delta Q_{\mathrm{arb}}}^{e}=g(\sigma_{\mathrm{IV}}-\sigma^{e})\ \text{(#21)}.
\]

\(\sigma^{e}\) = private vol expectation; not Algebra \(\sigma_X\).

---

## §3 — README & module sketch

### README surgery

**Keep:** affine split; measure pointer (#17–#18); canonical \(\sigma_{\mathrm{IV}}=2\phi\sqrt{V/L}=2\phi e^{u/2}\).

**Remove:** invalid ln-difference block, undifferentiated κ, bad local derivative, incomplete integral.

**Insert:** T0/T1/T2 table, calibration pin \(u^\star\), symbol hygiene paragraph, pointers to this spec and `STREAMING_PREMIUM.md`.

### Module: `Volatility.ImpliedVolatility`

**T0 exports (first implementation slice):**

```haskell
newtype LogVolLiquidityRatio = LogVolLiquidityRatio Integer

uStarFromCalibration
  :: VolatilityAverage   -- or tick-vol integer stand-in for σ_X
  -> FeePips             -- total φ this cycle
  -> LogVolLiquidityRatio

sigmaIVFromU
  :: LogVolLiquidityRatio
  -> FeePips
  -> ImpliedVolatility   -- newtype over same units as σ_X

sigmaIVCalibrated
  :: VolatilityAverage
  -> FeePips
  -> ImpliedVolatility
```

**Deferred:** `LiquidityGrowth`, `VolLiquidityElasticity`, `stepLogVolLiquidityRatio`, `U88LogRatio`.

**Tests (T0):** \(u^\star\) algebra matches Eq 3.16; at pin \(\sigma_{\mathrm{IV}}=\sigma_X\); reject README-invalid formulas in comments/docs only.

---

## Economic meaning

In a rates-only scratchpad, **trade volume in nominals is latent**. Kristensen implied vol is not computed from liquidity geometry alone; it is **read from** \(u=\ln(V/L)\). At fair adaptive fee, calibration pins \(u\) so market IV equals realized window vol \(\sigma_X\) — the streaming-premium / fee-revenue identity. Off-equilibrium, \(u\) must be carried by an observer or packed state; fee-mix \(\kappa\) controls \(\phi_X/\phi_M\) weighting in payoffs and is **not** the liquidity elasticity that moves \(u\) along tenor.

---

## Dependencies & order

```
TODO #20 T0 (this spec → plan → ImpliedVolatility.hs)
  → TODO #21 r_arb^e functional form
  → TODO #22 β
  → TODO #17–#18 measure m(·)
  → unblock TODO #6 r(0) composition
```

---

## Self-review

- [x] No TBD placeholders in locked sections (T1 observer coefficients deferred explicitly)
- [x] σ_IV read map consistent with STREAMING_PREMIUM Eq 3.16
- [x] κ vs κ_L disambiguated vs `KappaCoordinate`
- [x] Scope: T0 code + README; T1/T2 design-only
- [x] Single implementation plan target (#20)

---

## Handoff

After user approves this spec → invoke **writing-plans** for TODO #20 T0 (`Volatility.ImpliedVolatility` + README + tests). Open/update GitHub issue per `AGENTS.md`.
