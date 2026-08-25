# Scratchpad — price-update transfer: arbitrageurs as the buyer's delta-hedgers (replaces "MEV tax")

**Date:** 2026-08-25  
**Status:** design note (no reviewer pass, by user instruction). **§2 (Defs 9–11) superseded** by `2026-08-25-scratchpad-delta-hedge-rebate-design.md` (TODO #32); §1 Prop A and §3 stand.  
**TODO:** #31 — re-scopes #23/#34 (`volume_path.gms` coupling) and the \(\tau_{\mathrm{MEV}}\) objective  
**Notation anchor:** `VOLATILITY_INSTRUMENTS.md`; README § REPLICATION_THEORY, § CHANNEL_STATICS, § MODEL_CLOSURE

## 1. Claim

The contractual payoff \(\pi^\sigma=\Delta Q_\upsilon(\sigma(i(t))-\sigma_K)^+\) is on the **path variance of the pool tick**. The replica pays **terminal convexity** \(\sum_{\mathrm{leg}}[H_{\mathrm{leg}}-\pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};p_T)]\). The bridge between a terminal convex payoff and path variance is delta-hedging along the path (Demeterfi): hedging P&L of a convex position \(=\) realized variance. In a CFMM the trades that perform that hedge are the **arbitrageurs'**: each correction re-centres the pool at the external price and pockets the concavity gap, which is the gamma P&L (Theorem 5, Fact 2).

**Proposition A (roles).** Long Panoptic buyer = holder of the convexity. Arbitrageur = the hedger, who keeps the hedging P&L (LVR). Seller (LP whose liquidity is borrowed) = receives theta (streamia) from the buyer and pays gamma (LVR) to the arbitrageur. The three are one option position split across three agents.

Consequences:
- Arbitrageurs are not a negative externality on the instrument; they are the **only channel** by which \(\sigma(i(t))\) tracks external variance. Without them the pool price is stale inside the fee band and the replica's mark lags the contract.
- What is misallocated is the **surplus**: above the fee band the hedger is paid \(\mathrm{LVR}_{\mathrm{net}}>0\), far more than the update costs; below it the hedger is paid \(<0\) and the update does not happen (Fact 2, `panel-accrual-vs-vol.png`).

## 2. The transfer (replaces \(\tau_{\mathrm{MEV}}\))

**Definition 9 (signed price-update transfer).** \(s\) per unit of arb volume, token1, applied on arb-tagged steps: \(s<0\) is a **subsidy** paid from the streamia budget to the arbitrageur; \(s>0\) is a **tax** returned to the seller. Effective fee band for the arbitrageur: \(\phi_{\mathrm{eff}}=\phi-s\) (a subsidy narrows the band; a tax widens it).

**Definition 10 (budget).** \(\int (-s)^+\,d\nu_{\mathrm{arb}}\ \le\ \text{streamia}\) — subsidies are paid only out of what the buyer already pays the seller for the update service.

**Definition 11 (equilibrium / fair compensation).** \(s^\star\) such that \(\mathrm{LVR}_{\mathrm{net}}-s^\star\nu_{\mathrm{arb}}=0\): the arbitrageur earns exactly the update cost. Then the pool tracks the external price at tick resolution, the hedging P&L nets to the contract, and \(e^\sigma\) is reduced to the replication floor already measured (binning \(\approx S^2\), discretization \(O(\Delta_i)\)).

The objective \(\inf_\tau|\pi^\sigma-\hat\pi^\sigma([\nu_{\mathrm{arb}}/\nu](\tau))|\) survives with \(s\) in place of \(\tau\); its interior solution is no longer a trade-off between two harms but the **price of a service**.

## 3. Two sources of pool variance; what `volume_path.gms` is and is not

`volume_path.gms` takes a \(\delta_{\mathrm{trans}}\) shock with \(p_0=p_T\): a **transactional round trip**. Zero terminal move, positive pool-path variance, fees on both legs, **no LVR, no arbitrageur needed** — the price returns because the flow reverses, not because anyone corrected it. That is the regime in which the seller collects streamia for variance that arbitrageurs did *not* mint: the budget of Definition 10.

What GAMS does not produce is an **external price move** that the pool learns only through an arbitrageur: a permanent tick displacement with LVR.

\[
\sigma(i(t))\ \text{path}\;=\;\underbrace{\text{trans noise (GAMS round trips)}}_{\text{fees, no LVR; variance not minted by arbs}}\;+\;\underbrace{\text{arb corrections toward } P_{\mathrm{ext}}}_{\text{permanent moves, LVR; variance minted by arbs}}
\]

**Update rule.** An arbitrageur steps in when \(|p_{\mathrm{ext}}-p|>\phi_{\mathrm{eff}}=\phi-s\), moving \(p\) to \(p_{\mathrm{ext}}\) (or to the band edge). The arb share \([\nu_{\mathrm{arb}}/\nu]\) is then **produced** by the rule at a given \(s\) — this is the missing gate \(\tau\to[\nu_{\mathrm{arb}}/\nu]\), now with a mechanism.

## 4. Re-scoped #34 (TODO #23)

| half | source | produces | status |
|---|---|---|---|
| transactional | GAMS replay (`dQx`, `dQM`, `txlVolumeRate`, `volTgtWad`) | fees, \(\delta_{\mathrm{trans}}\), \(u=\ln(V/\bar L)\), the atomic \([\nu_{\mathrm{trans}}/\nu]\) as a **given** | unchanged from #34 |
| arbitrage | external process \(P_{\mathrm{ext}}\) (tick random walk with a vol parameter) + the update rule at \(s\) | permanent moves, LVR, \([\nu_{\mathrm{arb}}/\nu]\) as an **output**, the vol that enters \(\lambda_{X/M}\) | new |

`Payoffs.PathAccrual.syntheticPath` becomes the composition of the two halves: trans steps are round-trip noise, arb-tagged steps are **corrections toward \(P_{\mathrm{ext}}\) and nothing else**. `ArbSharePips` stays the atomic type; it is now read off the produced path rather than set.

## 5. What this changes downstream

- MODEL_CLOSURE §2: \(\lambda_{X/M}=\phi(2e^{u/2}-1)^+\chi(\mathcal{LC})\) is the band-crossing per-token rate with \(\phi\to\phi_{\mathrm{eff}}=\phi-s\); the "\(u\)" in it is the **external** half's vol, not the trans half's \(u\).
- README objective: \(\inf_{\tau_{\mathrm{MEV}}}\) → \(\inf_s\) subject to Definition 10; FOC unchanged in form (direct + gate), gate term \(\partial[\nu_{\mathrm{arb}}/\nu]/\partial s\) now computable from the update rule.
- #51 (\(\lambda_{X/M}\)) consumes the arb half; #7/#2 (\(\delta_{\mathrm{trans}}\), `ExpectedReturn`) consume the trans half.

## 6. Tests the note commits to (for the implementation item)

1. Round-trip GAMS path: LVR \(=0\), fees \(>0\), terminal replica \(=0\), pool-path variance \(>0\).
2. External-only path at \(s=0\): arb steps occur iff \(|p_{\mathrm{ext}}-p|>\phi\); \(\mathrm{LVR}_{\mathrm{net}}\) crosses zero at the band (Fact 2 reproduced by the rule, not by a tag schedule).
3. Subsidy: \(s<0\) increases \([\nu_{\mathrm{arb}}/\nu]\) and decreases the stale-mark error; budget constraint binds before \(\phi_{\mathrm{eff}}\le0\).
4. Equilibrium: at \(s^\star\) of Definition 11 the arbitrageur's net is \(0\) within X96 tolerance.

## 7. Economic meaning

Streamia is the option's theta. LVR is the option's gamma P&L, earned by whoever hedges. In a CFMM the hedger is the arbitrageur, so the instrument's seller pays gamma to a third party and receives theta from the buyer; the transfer \(s\) is the market for the hedging service — a subsidy when hedging is under-supplied (vol below the fee band), a rebate of surplus when it is over-paid (vol above it). "Tax" was the wrong word because the sign is not fixed.
