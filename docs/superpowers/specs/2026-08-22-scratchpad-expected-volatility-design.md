# Scratchpad ExpectedVolatility σ^e — design

**Status:** done — plan `docs/superpowers/plans/2026-08-22-scratchpad-expected-volatility.md` (Slice 1)  
**Date:** 2026-08-22  
**Repo:** `cfmm-theory` / package `scratchpad/`  
**Brainstorm:** σ^e as risk-neutral expectation of realized vol; dual horizon (WINDOW + tenor)  
**Prereqs:** TODO #20 (`ImpliedVolatility` / σ_IV); TODO #17–#18 (measure Q via `DiscountFactor` / `Expectation`)  
**Related:** `docs/superpowers/specs/2026-08-22-scratchpad-sigma-iv-latent-u-design.md`

**Reads:** `Volatility/TickVolatility.hs`; `Pricing/InterestPriceMap.hs`; `cfmm-options/IMPLIED_VOLATILITY.md`; `scratchpad/README.md` (return split)

---

## Purpose

Define **expected volatility** \(\sigma^{e}\) used in the arb return leg
\(r_{\Delta Q_{\mathrm{arb}}}^{e}=g(\sigma_{\mathrm{IV}}-\sigma^{e})\) as a
**risk-neutral expectation of future realized volatility** \(\sigma_X\), with
EVM-friendly typing (oracle-integer units) and two horizon constructors.

**Replaces** informal “private vol expectation” wording in TODO #21.

**Out of scope this spec:** full `DiscountFactor` (#17), `Expectation` (#18),
functional form of \(g\) (#21 feat slice), β (#22), Solidity, u88 packing.

---

## §1 — Definition

### Realized vol (observable today)

\[
\sigma_X(t) = \bar\sigma_X(t,\,\mathrm{WINDOW})
\]

Algebra trailing-window mean of `_volatilityOnRange` — scratchpad:
`VolatilityAverage` / `averageVolatility` (`Volatility.TickVolatility`).

Look-ahead-free on-chain (`VolatilityOracle`, `WINDOW = 1 day`).

### Implied vol (TODO #20)

\[
\sigma_{\mathrm{IV}}(t) = 2\phi\, e^{u(t)/2},\quad u=\ln(V/L).
\]

See latent-\(u\) spec. Distinct economic object from \(\sigma^{e}\).

### Expected vol (this spec)

\[
\sigma^{e}(t;\,\tau)
:=
\mathbb{E}^{\mathbb{Q}}\!\left[
  \bar\sigma_X\!\big(\text{forward horizon } \tau\big)
  \;\middle|\; \mathcal{F}_t
\right].
\]

- \(\mathbb{Q}\): martingale measure from \(m(\Delta Q)\) / \(m(\phi)\) (#17–#18)
- Same **units** as `VolatilityAverage` (Algebra raw integer, unbounded)
- **Not** FeePips, **not** u88 sqrt-price trick

### Arb gap

\[
\mathrm{VolGap} := \sigma_{\mathrm{IV}} - \sigma^{e},
\qquad
r_{\Delta Q_{\mathrm{arb}}}^{e} = g(\mathrm{VolGap})\ \text{(#21)}.
\]

---

## §2 — Dual horizon (constructor C)

```haskell
newtype ExpectedVolatility = ExpectedVolatility Integer

data VolHorizon
  = OracleWindowHorizon       -- τ ≡ WINDOW (1-day oracle semantics)
  | TenorHorizon InterestTick -- τ ≡ path to tenor tick t_r
```

| Constructor | Horizon τ | Primary use |
|-------------|-----------|-------------|
| `OracleWindowHorizon` | Next oracle `WINDOW` | Default arb; aligns with adaptive-fee \(\sigma_X\) |
| `TenorHorizon t_r` | Swap/fee tenor to \(t_r\) | Payoff-aligned \(g(\sigma_{\mathrm{IV}}-\sigma^{e})\) at same \(t_r\) as mixture |

### OracleWindowHorizon

\[
\sigma^{e,\mathrm{win}}(t)
=
\mathbb{E}^{\mathbb{Q}}\!\left[
  \bar\sigma_X(t+\mathrm{WINDOW},\, \mathrm{WINDOW})
  \;\middle|\; \mathcal{F}_t
\right].
\]

Discrete twin: weighted ensemble of `averageVolatility` over risk-neutral tick
paths on \([t,\, t+\mathrm{WINDOW}]\).

**EVM:** realized = one oracle read; expected = stored/computed integer word
updated by model/controller (not a single static oracle call).

### TenorHorizon

\[
\sigma^{e,\mathrm{ten}}(t;\, t_r)
=
\mathbb{E}^{\mathbb{Q}}\!\left[
  \bar\sigma_X\!\big(\text{along InterestPriceMap path } t \to t_r\big)
  \;\middle|\; \mathcal{F}_t
\right].
\]

Discrete twin: `TickPath` from `priceTickAt` along `[t0 .. t_r]`; weight segments
with same \(m\) that prices \(\pi^{\Delta Q}\) on that path.

**Payoff alignment:** use matching \(t_r\) for mixture \(r^e\) / \(r_\phi^e\) and
for \(\sigma^{e,\mathrm{ten}}(t;\, t_r)\).

---

## §3 — Module layout & implementation slices

### Module: `Volatility.ExpectedVolatility`

**Slice 1 (first plan — no `DiscountFactor` yet):**

| Symbol | Role |
|--------|------|
| `ExpectedVolatility` | newtype over `Integer` |
| `VolHorizon` | WINDOW \| Tenor |
| `RealizedVolatility` | wrapper for \(\sigma_X\) reads |
| `VolGap` | \(\sigma_{\mathrm{IV}} - \sigma^{e}\) |
| `realizedVolatilityFromAverage` | `VolatilityAverage -> RealizedVolatility` |
| `expectedVolatilityUniformTenor` | stub: uniform weights on tenor path |
| `volGap` | `ImpliedVolatility -> ExpectedVolatility -> VolGap` |

**Slice 2:** weights from mixture / proxy for \(m\).

**Slice 3:** `expectedVolatility :: DiscountFactor r => VolHorizon -> r -> ExpectedVolatility`.

### Measure link (#17–#18)

\[
\mathbb{E}^{\mathbb{Q}}[X]
=
\frac{\mathbb{E}^{\mathbb{P}}[m(\Delta Q)\,X]}{\mathbb{E}^{\mathbb{P}}[m(\Delta Q)]}
\]

Apply to \(X=\bar\sigma_X\) on WINDOW ensemble or tenor `TickPath`.

### EVM typing

| Layer | Representation |
|-------|----------------|
| Realized \(\sigma_X\) | `getAverageVolatility` → unbounded int |
| Expected \(\sigma^{e}\) | same integer units; `ExpectedVolatility` newtype |
| Horizon | enum / tag byte (`OracleWindow` vs `tenorTick`) |
| u88 | optional **pack** of same integer (T2); not different units |

---

## Equilibrium checks (tests)

| Pin | Condition | Expected |
|-----|-----------|----------|
| 1 | Fair fee, T0 \(u=u^\star\) | \(\sigma_{\mathrm{IV}} = \sigma_X\) |
| 2 | Calibration + \(\mathbb{Q}\) at equilibrium | \(\sigma^{e,\mathrm{win}} = \sigma_X\) |
| 3 | Tenor horizon at current tick (uniform stub) | \(\sigma^{e,\mathrm{ten}}(t;t) \approx \sigma_X(t)\) |
| 4 | Pins 1–2 | `volGap` = 0 |

Reject conflation with `FeePips` or plank u88 sqrt encoding.

---

## Economic meaning

\(\sigma^{e}\) is the **risk-neutral price of future realized tick variance** —
the same object the Algebra oracle measures ex-post (\(\sigma_X\)), but carried
forward under \(\mathbb{Q}\) induced by trade/fee measure \(m\). The arb leg
\(g(\sigma_{\mathrm{IV}}-\sigma^{e})\) prices the wedge between Kristensen
implied vol (latent volume/liquidity ratio) and that expected realized vol.
WINDOW horizon matches adaptive-fee control; tenor horizon matches swap/fee
capture paths so arb pressure is evaluated on the same clock as \(r^e\).

---

## Dependencies

```
#20 ImpliedVolatility (σ_IV)
  → #21 ExpectedVolatility (σ^e) Slice 1 + volGap
  → #21 feat g(·) and r_arb^e wire
  → #22 β
  → #17–#18 full E^Q
  → #6 r(0) composition
```

---

## Self-review

- [x] σ^e defined as E^Q[realized σ_X], not private belief
- [x] Dual horizon C documented
- [x] Oracle integer units pinned; u88 deferred as pack-only
- [x] Slice 1 bounded without #17–#18
- [x] Distinct from σ_IV latent-u spec

---

## Handoff

After user approves → **writing-plans** for TODO #21 Slice 1
(`Volatility.ExpectedVolatility` + tests + README). Open GitHub issue per `AGENTS.md`.
