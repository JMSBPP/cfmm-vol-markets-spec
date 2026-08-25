# Scratchpad — holder-hedged replication: the delta-hedge rebate (supersedes the signed transfer \(s\))

**Date:** 2026-08-25  
**Status:** design note (no reviewer pass, by user instruction)  
**TODO:** #32 — supersedes §2 (Defs 9–11) of `2026-08-25-scratchpad-price-update-transfer-design.md`; re-scopes #34 (TODO #23)  
**Notation anchor:** `VOLATILITY_INSTRUMENTS.md`; README § REPLICATION_THEORY, § CHANNEL_STATICS, § MODEL_CLOSURE

## 0. Why not \(s\), why not an auction

Proposition A (transfer note) stands: the arbitrageur is the buyer's delta-hedger and keeps the gamma P&L. The signed transfer \(s\) prices that service but must be *solved* (\(s^\star\) needs the external vol). Auctioning the arbitrage slot discovers the same price, but that is Angstrom's product and closed to composition. Both keep the hedge outsourced.

The textbook replication (Demeterfi) does not outsource it: **log contract + the holder's own delta hedge in the underlying.** In a CFMM the holder's hedge trades are trades against the pool, i.e. they *are* the price updates. So the mechanism is: let the buyer hedge, and refund the fee on the delta-sized portion of those trades out of the streamia the buyer already pays. Nothing to solve, no oracle, composable (a per-swap accounting rule on the holder's own trades).

## 1. Objects

**Definition 12 (replica delta).** With \(P = p^2\) (price, token1 per token0),
\[
\hat\Delta^\sigma(p) \;=\; \partial_P\,\hat\pi^\sigma(p) \;=\; \sum_{\mathrm{leg}}\Big[\partial_P H_{\mathrm{leg}} - \partial_P\,\pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};P)\Big],
\]
token1 per unit price. Per leg it is the three-piece derivative of `LadderPrincipal.principal` in \(P\) (0 below the range, \(L/(2p)\)-type slope in range, constant \(\text{amount0}\) above) minus the \(H_{\mathrm{leg}}\) slope (0 for puts, \(\text{amount0}\) for calls). \(\hat\Delta^\sigma(p^\star)=0\); \(\hat\Delta^\sigma>0\) above \(p^\star\), \(<0\) below (long convexity). Type `DeltaX96` (signed Integer, token1/price at Q96). Lean twin: `principal_price_deriv`, next to `principal_price_second_deriv` (peer item).

**Definition 13 (hedge ledger).** Per position, state \((h, B_s, B_r)\): \(h\) = token1 delta already hedged (signed); \(B_s\) = streamia paid so far; \(B_r\) = rebates paid so far. **Invariant** \(B_r \le B_s\).

**Definition 14 (qualifying amount and rebate).** For a holder swap \(p_{\mathrm{before}}\to p_{\mathrm{after}}\) with signed token1 flow \(q\): target \(\Delta^\ast = \hat\Delta^\sigma(p_{\mathrm{after}})\); qualifying flow \(q^\ast\) = the portion of \(q\) that moves \(h\) toward \(\Delta^\ast\),
\[
q^\ast = \operatorname{sgn}(\Delta^\ast - h)\cdot\min\big(|q|,\,|\Delta^\ast - h|\big)\ \text{ if } \operatorname{sgn}(q)=\operatorname{sgn}(\Delta^\ast-h),\quad 0 \text{ otherwise};
\]
rebate \(\rho = \min\big(\phi\,|q^\ast|,\ B_s - B_r\big)\) in token1; then \(h \leftarrow h + q^\ast\), \(B_r \leftarrow B_r + \rho\). Non-holder swaps: no change. Re-submitting a delta already in \(h\) gives \(q^\ast = 0\), \(\rho = 0\) — no double claim by construction.

Fee source is the streamia escrow (the holder pays full \(\phi\) on the swap; the refund comes from \(B_s\)), so the fee channel of CHANNEL_STATICS (Fact 1, `stepAccrual`) is untouched and LPs keep their fees.

## 2. Economics

**Proposition B (holder-hedged replication).** Over a tick path \(p_0,\dots,p_T\) with the holder hedging at ticks \(t_1<\dots<t_n\),
\[
\text{P\&L}_{\mathrm{holder}} \;=\; -(B_s - B_r)\;+\;\sum_{k}\text{gamma gain}_k\;+\;\big[\hat\pi^\sigma(p_T)-\hat\pi^\sigma(p_0)\big],
\]
where gamma gain\(_k\) is the hedge P&L between consecutive hedges (the concavity gap of Theorem 5 with the sign reversed — the holder is long convexity). With continuous hedging \(\sum_k \text{gamma gain}_k = \tfrac12\int\hat\Gamma\,dP^2\), the Demeterfi replication of \(\int\sigma^2\): the contract \(\pi^\sigma\). Discrete hedging at stride \(\Delta_i\) adds an \(O(\Delta_i)\) term on top of the T2 binning floor \(e^\sigma_W(\mathcal{B})\).

Consequences:
- Defs 9–11 are retired. The budget is the ledger invariant; the equilibrium is not solved — the holder hedges whenever \(|\Delta^\ast - h|\) exceeds the gas cost of a swap.
- Both regimes of Fact 2 are fixed with one sign: inside the fee band the holder updates (fee-free at the margin, any gap is profitable to them) so there is no stale-mark zone; above the band the holder is first in line at \(\phi_{\mathrm{eff}}=0\), so the surplus that arbitrageurs used to take accrues to the buyer, whose gamma it was.
- Arbitrageurs are residual: they close gaps larger than the holder's remaining delta. \([\nu_{\mathrm{arb}}/\nu]\) is read off the path as an output (transfer note §3), never set.
- MODEL_CLOSURE §2: \(\lambda_{X/M}\) keeps its form with \(\phi_{\mathrm{eff}}=0\) on holder steps and \(\phi\) on residual arb steps.

## 3. Re-scoped #34 (TODO #23)

| half | source | produces |
|---|---|---|
| transactional | GAMS replay (`dQx`, `dQM`, `txlVolumeRate`, `volTgtWad`) | fees, \(\delta_{\mathrm{trans}}\), \(u\), atomic \([\nu_{\mathrm{trans}}/\nu]\) (given) |
| holder hedge | ledger of Def 13 stepping on the trans path + an external process \(P_{\mathrm{ext}}\) used only to *simulate the holder's decision* | rebates, \(h\)-path, gamma gains, holder P&L |
| residual arb | gaps left after holder steps, closed at \(\phi\) | LVR, \([\nu_{\mathrm{arb}}/\nu]\) as output |

`Payoffs.PathAccrual` gains a `Holder` tag; `syntheticPath` becomes the composition of the three.

## 4. Haskell surface (no code in this note)

- `Payoffs.ReplicaDelta`: `replicaDelta :: MintPlan -> SqrtPriceX96 -> DeltaX96`, per-leg terms; test = central difference of `fourLegReplica`.
- `Hedge.Ledger`: `data Ledger = Ledger { hedged :: Integer, streamiaPaid :: Integer, rebated :: Integer }`, `hedgeStep :: FeePips -> MintPlan -> Ledger -> Swap -> (Ledger, RebateX96)` — pure, Def 14 verbatim, `mulDiv` forms, uint128 checks (docs/BITWIDTHS.md row).
- `Payoffs.PathAccrual`: `Holder` tag, `holderPnL`.
- Axes: rebate/streamia in pips (uint24), \(h\) as raw token1, ticks. No Double.

## 5. Tests the note commits to

1. \(\hat\Delta^\sigma\) matches the central difference of \(\hat\pi^\sigma\) within X96 tolerance; \(=0\) at \(p^\star\); sign as in Def 12.
2. Ledger: \(B_r \le B_s\) on every step; re-submitting the same delta yields \(\rho = 0\).
3. Round-trip GAMS path: the holder hedges out and back; \(\sum\rho\) = fees on the qualifying portions; holder net \(=\sum\) gamma gains \(\ge 0\).
4. Convergence: hedging at stride \(\Delta_i\), \(|\text{P\&L}_{\mathrm{holder}} - \pi^\sigma|\) decreases with \(\Delta_i\) and floors at \(e^\sigma_W(\mathcal{B})\).
5. Stale mark: on an external-move path the gap after each holder hedge is \(\le\) the gas threshold — no fee-band-wide stale zone (Fact 2's undersupply regime is gone).

## 6. Economic meaning

The buyer of the volatility payoff pays theta (streamia) and is owed gamma. Under outsourced hedging, gamma leaks to arbitrageurs and the buyer only recovers it if a transfer is priced correctly. Under holder hedging, the buyer spends their own theta to collect their own gamma: the rebate is not a payment to anyone, it is the streamia returned to the extent it funded the hedge that makes the replica pay. The pool tracks the external price because the person with the largest stake in that tracking is the one with the cheapest trade. "Tax", "subsidy" and "rent" all priced a third party; there is no third party.
