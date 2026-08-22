
# PRIMITIVES



# PAYOFFS
Consider:


For the payoff type \(\pi (K; P)\) we have:


\[
	\begin{aligned}
	    \pi (K \, + \, \Delta K; P) \, &=  \pi (K; P) \, + \, \Delta K \, \frac{\partial \pi (K; P)}{\partial K}
	\end{aligned}
\]

This is an endomorphism on the payoff space:
\[
	\begin{aligned}
	    \mathcal{D}_{\Delta K}^K \, &\equiv \, \pi (K; P) \, + \, \Delta K \, \frac{\partial \pi (K; P)}{\partial K}
	\end{aligned}
\]


Then: 

\[
	\begin{aligned}
		\pi (K \, + \, \Delta K; P) \, &= \mathcal{D}_{\Delta K}^K \, \pi (K ; P)
	\end{aligned}
\]



# RANGE_ACCRUAL_NOTE

where

\[
\pi^{\text{RA}}(k,r;p)=
\begin{cases}
	0, & p < \frac{k}{r}, \\[4pt]
	\dfrac{2\sqrt{pkr} - pr - k}{r-1}, & \frac{k}{r} \le p < k, \\[8pt]
	\dfrac{2\sqrt{pkr} - p - kr}{r-1}, & k \le p < kr, \\[8pt]
	0, & p \ge kr.
\end{cases}
\]


The sqrt-coordinate range payoff is


\[
	\begin{aligned}
		\pi^{\text{RA}}(\kappa, r; p_{1/2}) =
			\begin{cases}
		0, & p_{1/2} < k_{1/2}/\sqrt{r}, \\[4pt]
		\dfrac{2\cdot p_{1/2} k_{1/2} \sqrt{r} - p_{1/2}^2r - k_{1/2}^2}{r-1}, & k_{1/2}/\sqrt{r} \le p_{1/2} < k_{1/2}, \\[8pt]
		\dfrac{2p_{1/2}k_{1/2}\sqrt{r} - p_{1/2}^2 - k_{1/2}^2r}{r-1}, & k_{1/2} \le p_{1/2} < k_{1/2}\sqrt{r}, \\[8pt]
		0, & p_{1/2} \ge k_{1/2}\sqrt{r}.
			\end{cases}
	\end{aligned}
\]


## PRICING GEOMETRY


There is a dimensional issue when **raising a dimensional quantity to a power (\eta)** changes its dimension

\[
	\begin{aligned}
		p_{\eta} (i) \, &= (p_{1/2} (i))^{1/\eta}
	\end{aligned}
\]


Consider reference price \(\bar p_{1/2}\), then we want to define as:

> Note that at a module level \(\bar p_{1/2}\) is a constant Lets make it the 0 price in its respective Q96 representation
\[
	\begin{aligned}
		p_{1/2} (i; \eta) &= \bar p_{1/2} \, \Big (\frac{p_{1/2} (i)}{\bar p_{1/2}}\Big)^{\varsigma (\eta)}; \, \varsigma (\frac{1}{2}) = \frac{1}{2} 
	\end{aligned}
\]


Then the structure is now


```
src/
├── Payoffs/  // payoffs and returns only
│   ├── Payoff.hs
│   ├── CoveredCall.hs
│   ├── CashSecuredPut.hs
│   ├── RangeAccrualNote.hs
│   ├── CLMMPosition.hs
│   ├── VolatilityCall.hs
│   ├── Forward.hs
│   ├── Log.hs
│   ├── Linear.hs
│   ├── Return.hs
│   ├── Savings.hs
│   ├── Swap.hs
│   ├── TransactionalFeeCapture.hs
│   └── VariancePortfolio.hs
├── Panoptic/
│   ├── NId.hs
│   └── MintPlan.hs
├── Plotting/
│   ├── PlotSqrt.hs
│   ├── PlotInterest.hs
│   └── PlotUtils.hs
├── Pricing/
│   ├── PriceDeformation.hs
│   ├── Stremia.hs
│   ├── AdaptiveStremia.hs
│   ├── FeeStructure.hs
│   ├── MarkUpStructure.hs
│   ├── ExpectedReturn.hs
│   ├── DiscountFactor.hs   // planned (TODO #17): parametric m(·)
│   ├── InterestSqrt.hs
│   └── InterestPriceMap.hs
├── Trading/
│   ├── PriceImpact.hs
│   ├── Quote.hs
│   └── KappaCoordinate.hs
├── Greeks/
│   ├── Delta.hs
│   ├── Gamma.hs
│   ├── Theta.hs
│   └── Vega.hs
├── Liquidity/
│   ├── LiquidityChunk.hs
│   ├── LiquidityGrid.hs
│   ├── LiquidityDensity.hs
│   └── TickLiquidity.hs
├── Volatility/
│   ├── VolOrder.hs
│   ├── VolatilityGrid.hs
│   ├── VolTermStructure.hs
│   ├── TickVolatility.hs
│   └── CevField.hs
├── TickPath.hs
├── SqrtGrid.hs
├── StrikeX96.hs
├── OptionRatio.hs
├── TargetVega.hs
└── State.hs

outputs/{Pricing,Payoffs,Payoffs/Returns,Greeks,Liquidity,TickPath,Volatility}/
```

> Tree lists **current** modules.

- `Payoffs.Linear.linearPayoff`: standardized linear \(P=s^2\) as `PayoffX96`.
- `Payoffs.Return.ReturnPips` / `mkReturn`: ppm return of one level vs another (`returnPipsScale = 10^6`).
- `Plotting.PlotSqrt.PlotY`: `PayoffY` | `ReturnY` on sqrt-series plots; return PNGs under `outputs/Payoffs/Returns/`.
- `SqrtGrid`: \(\lambda=1.0001\), `TickSpacing` \(\Delta_i\in[1,200]\)
- `Pricing.InterestSqrt`: `InterestTick` / `InterestSqrtX96` — \(\lambda^{t/2}\) twin of price `Tick` / `SqrtPriceX96` (interest dimensions; \(1+r=\lambda^{t}\))
- `Payoff u`: parametric underlying (`SqrtPriceX96` | `InterestSqrtX96`, …)
- `Payoffs.Savings.savingsPayoff` / `savings`: \(Y=s_r^{2}=\lambda^{t}\); plot `outputs/Payoffs/savings-vs-interestSqrtX96.png`
- `Payoffs.Swap`: Pay/Receive phantoms; `swapFromFeeStructure` → pay Linear×(1-φ_X) vs sqrt, receive Savings×(1-φ_M) vs interest; net along \(i=kt+i_0\) (`outputs/Payoffs/swap-*-vs-*.png`, `swap-net-vs-interestSqrtX96.png`)
- `Payoffs.TransactionalFeeCapture`: \(\pi^\phi=\phi_X P+\phi_M I\); sum along tenor; identity with Swap; plots `fee-capture-*-vs-*.png`
- `Pricing.InterestPriceMap`: \(i=k t+i_0\) (caller `i_0`, default `k=1`)
- `LiquidityGrid`: \(\xi\) is the liquidity base (like \(\lambda\) for price). Canonical \(Y\) is Bunni `uint256 liquidityDensityX96` (Q96), the Haskell type `LiquidityDensityX96`. \(\iota\) is ladder length, not \(\eta\).
- `VolatilityGrid`: \(\Gamma_{\varphi}(i)\) coordinate. Canonical field \(\pi_{\sigma}\) is unit-notional `VolatilityCall` on that X.
- `VolTermStructure` / `TickPath` / `TickVolatility`: PricePaths layer (below).
- `CevField`: static CEV \(\sigma(i)=\texttt{volAt}\,i=\delta/p_{1/2}(i)\), plotted under `outputs/Volatility/`.
- `Greeks.Gamma`: Kristensen \(\partial^2V/\partial P^2\), not \(\Gamma_{\varphi}\). Interior \(-\Gamma\) vs `gammaCoordinate` is the tautological ray (`outputs/Greeks/vs-gammaCoordinate.png`).

Main chooses which panels to write.

Atlas rule: each folder has one canonical Y; `vs-*` only changes X.

| Folder | Canonical Y | vs-xiCoordinate | vs-gammaCoordinate | vs-sqrtPriceX96 |
|---|---|---|---|---|
| Liquidity | `liquidityDensityX96` | done | done | done |
| Payoffs (\(\pi_\sigma\)) | Algebra `(S−K)+` | done | done | done |
| Volatility (CEV) | `volAt` = \(\delta/p_{1/2}(i)\) | done | done | done |

vs-gamma for \(\pi_\sigma\): expected \(Y\propto(j+1)^2\) vs growing \(\Gamma_\varphi\) (visual floor is \(K=0\) scale, not a vanilla kink). \(Y\propto(\log\Gamma_\varphi)^2\).

Do not plot `liquidityDensityX96` as a VolatilityCall Y (already the Liquidity atlas). \(\xi\) as X for \(\pi_\sigma\) is the decreasing dual of vs-gamma.

CEV plots matter: they are the static \(\sigma(i)\) `VolTermStructure` was built for; B1 tick² is not that field. vs-sqrtPrice CEV is \(\sigma\propto 1/p\).

Do not feed `volAt` into `VolatilityCall.payoff` (CEV return vol ≠ Algebra tick²).

Liquidity density (`uint256 liquidityDensityX96`) is plotted against each atlas X, in this order:

- `outputs/Liquidity/vs-xiCoordinate.png`
- `outputs/Liquidity/vs-gammaCoordinate.png`
- `outputs/Liquidity/vs-sqrtPriceX96.png`

Tick path (this round):

```
cevFromPhi η L̄ σ_F → VolTermStructure → TickPath N seed i0 → ticks vs steps
                                                      ↓
                                              TickVolatility → σ_X
```

- \(T = N\), one step is one time unit; Algebra window is the whole path (`WINDOW := N`).
- CES constructor is \((\eta, \bar L, \sigma_F)\) only. First inhabitant `BASE_ETA` (CPMM \(\beta=\eta=1/2\)). Maymin \(\delta = 2\sigma_F/\bar L\) is derived.
- Four σ’s: \(\sigma_F\) = flow input; \(\sigma(i)\) = `volAt`; \(\sigma_X\) = Algebra window mean (`VolatilityAverage`); strike \(\sigma_K^2\) for the call is `VolStrike` (same Algebra raw integer as \(S\)).
- MEV (\(P_{\mathrm{trade}}\), \(a_t\), …) maps **into** \(\sigma_F\) later (`flowVolFromMev`); not fields of `cevFromPhi`.
- Plot: `outputs/TickPath/vs-steps.png` (Y = tick, X = steps).
- Unit-notional \(\pi_\sigma=(S-K)^+\) (`Payoffs/VolatilityCall.hs`): \(S\) is `_volatilityOnRange` on the **static book** \(i\to i+\Delta_i\) (same rungs as Liquidity vs-gamma), not a CEV `TickPath`. \(K\) is Algebra-raw `VolStrike`. Plots: `outputs/Payoffs/vs-{gammaCoordinate,sqrtPriceX96,xiCoordinate}.png`.

CEV field plots: `outputs/Volatility/vs-{sqrtPriceX96,gammaCoordinate,xiCoordinate}.png`.

Hop A (money view): \(N_{\mathrm{id}}=2/N\), `Forward.hs` / `Log.hs` on linear \(P\) (`squareSqrtPrice`, never \(s-s^\star\)), opaque \(\Pi\) (`fromLegs` = `fromDef6` at ATM), then \(\pi_{96}=\Delta Q_v\cdot\Pi_{\mathrm{opt}}\). Plot: `outputs/Payoffs/variance-portfolio.png` (Y = `PayoffX96`, not clipped at 0). `targetVega` is raw \(L\), not a vol word.

Hop B (in `NId.hs` / `MintPlan.hs`, under Hop A): EVM `PanopticTokenId` `{tokenId, numLegs}` + `MintPlan` `{mintTokenId, mintChunk :: LiquidityChunk}`. `PanopticTokenId` and `MintPlan` live in `Panoptic/MintPlan.hs` (split out of `NId.hs` so `TargetVega.hs` — needed by `Volatility/VolOrder.hs`'s `targetVega` field — does not import `NId`, avoiding a module cycle now that `NId` consumes `VolOrder` directly); `NId.hs` re-exports both. The 4-leg all-long tokenId is geometry-derived via `volOrderToTokenId :: VolOrder -> poolId -> ratios -> PanopticTokenId` (per-leg `optionRatio` 4-tuple in \(1..127\), puts below \(i^\star\), calls above; intervals and \(\Delta\) come from `legIntervals` / `tickBucketFromVolOrder`, not hardcoded ticks); `fourLegSkeleton` is now a thin wrapper calling `volOrderToTokenId` on `fixtureSymmetricVolOrder`. `volOrderToMintPlan` completes the `VolOrder → MintPlan` map: `mintChunk = createChunk i_l i_u (unTargetVega (volTargetVega vo))`, i.e. the envelope chunk at the order's `targetVega` (id is scale-free, including the ratio shape). Feasibility guards (each leg span \(\ge\Delta\); each side of \(i^\star\) \(\ge 2\Delta\)) `error` on infeasible `VolOrder`s. Dual-run: \(\pi_{96}\) from scalar \(\Delta Q_v\) equals \(\pi_{96}\) from `targetVegaFromMint`. The non-EVM `FourLegId` stub is gone. Hop C: `targetVegaFromMints` is additive. Not an on-chain `VolOrder` pack.

`Volatility/VolOrder.hs`: Plank-faithful `VolOrder {volRangeWidth, volStrike, volSkew, volTargetVega}`. `tickBucketFromVolOrder` maps `volStrike` + `volSkew` + `volRangeWidth` → `(i_l, i_u, Δ)`; `legIntervals` splits that bucket at \(i^\star\) and the two midpoints into the four leg intervals `[i_l,m_p],[m_p,i^\star],[i^\star,m_c],[m_c,i_u]`. `fixtureSymmetricVolOrder` is the canonical symmetric fixture (\(\Delta=10\), \([-20,20]\) about tick 0).

`Liquidity/LiquidityChunk.hs`: Panoptic `LiquidityChunk.sol` twin — opaque word packing `{tickLower, tickUpper, liquidity}` via `createChunk` / `chunkTickLower` / `chunkTickUpper` / `chunkLiquidity`. Not Bunni `LiquidityDensityX96`.

Hop B atlas (two-sided ticks \(i\in[-160,150]\), \(\Delta=10\), \(\iota=32\); Y = `PayoffX96` from `MintPlan`, not Algebra `(S-K)+`): `outputs/Payoffs/variance-portfolio-vs-{gammaCoordinate,xiCoordinate}.png`. Does not overwrite `outputs/Payoffs/vs-*.png`.

- Density→Panoptic ratio brainstorm (no implementation): [`docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md`](../docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md)



Note from VOLATILITY_INSTRUMENTS.md — canonical fee / return algebra (aligned with shipped code + `TODO.md` planned split).

### Stremia bid/ask (linear \(P\); sqrt via \(\sqrt{1+\phi}\))

\[
p_{\varphi}^{(\mathrm{ask})} = (1+\phi)\,p_{\varphi},
\qquad
p_{\varphi}^{(\mathrm{bid})} = \frac{p_{\varphi}}{1+\phi}
\]

Atlas map: \(p_{\varphi} \to p_{1/2}\).

**Shipped** — \(p_{1/2}^{(\mathrm{bid/ask})}\):
- payoffs: `Pricing.Stremia.nakedAskQ96` / `nakedBidQ96` (linear \(P\times(1+\phi)\))
- quotes: `Trading.PriceImpact.askSqrtPriceX96` / `bidSqrtPriceX96` (\(s\sqrt{1+\phi}\))
- `Trading.Quote`: mid+bid/ask `SqrtPriceX96` → \(\phi_M\leftarrow\phi(\mathrm{ask})\), \(\phi_X\leftarrow\phi(\mathrm{bid})\) (may differ)
- equal-φ special case: `feePipsFromBidAsk mid bid ask` (agree ≤1 pip)
- plots: `outputs/Payoffs/Returns/stremia-bid-ask.png`, `stremia-fee-vs-return.png`, `stremia-fee-rate-vs-sqrt.png`

Given a `Quote` with bid/ask on \(p_{1/2}\):

\[
\bigl(\phi(p_{1/2}^{(\mathrm{ask})}),\;\phi(p_{1/2}^{(\mathrm{bid})})\bigr)
\quad\Longrightarrow\quad
\phi_M \leftarrow \phi(\mathrm{ask}),\;
\phi_X \leftarrow \phi(\mathrm{bid})
\]

Adaptive markup (stub): \(\phi(\Theta_\phi;\sigma^2,\nu)\) in `AdaptiveStremia`.

### Fee bag (survival composite)

\[
\mathrm{FeeStructure} = \{\phi_X,\phi_M\},
\qquad
\phi \equiv 1-(1-\phi_M)(1-\phi_X)
\]

- `Pricing.FeeStructure`: bag `{φ_X, φ_M}`; survival `toFeePips` → \(1-(1-\phi_M)(1-\phi_X)\)
- `Pricing.MarkUpStructure`: markup bag class; `foldMarkUpFactor` = \(\prod_i(1+m_i)\); `TwoSidedMarkUp` exposes φ_X/φ_M; `FeeStructure` implements both; survival `toFeePips` unchanged
- `FeePips` is a `Monoid` (same survival stack); `FeeStructure` is not

### Swap survival legs

\[
\pi^{\Delta Q}_{\mathrm{pay}} = P_{1/2}(1-\phi_X),
\qquad
\pi^{\Delta Q}_{\mathrm{recv}} = I(r_{1/2})(1-\phi_M)
\]

(`Payoffs.Swap.swapFromFeeStructure`; net along tenor: recv − pay.)

### κ expected return (shipped)

Lattice \(\kappa_j = j/N\), \(N=255\) — **encoding C**: `KappaTick` / `KappaSpacing`; B (`KappaPips`) retired. Def 45 `kappaAt (Maybe EtaX96) XiX96 LiquidityChunk` → `KappaCoordinate`.

\[
r(\kappa;\phi_X,\phi_M)
=
(1-\kappa)\,\phi_X + \kappa\,\phi_M
\]

Composite survival fee when needed: \(\phi \equiv 1-(1-\phi_M)(1-\phi_X)\) (`toFeePips`).


| Index | Role | Expected return |
|-------|------|-----------------|
| \(m(\Delta Q)\) | swap / \(\Delta Q\) channel | \(r^e_{\pi^{\Delta Q}} \equiv \mathbb E[m(\Delta Q)\cdot \pi^{\Delta Q}]\) |
| \(m(\phi,\Delta Q)\) | fee revenue via swap leg | \(\mathbb E[m(\phi,\Delta Q)\cdot \pi^{\Delta Q}]\) |
| \(m(\phi)\) | fee revenue on \(\pi^\phi\) directly | \(r_\phi^e \equiv \mathbb E[m(\phi)\cdot \pi^\phi]\) |

General price form (fee leg): \(\mathbb E^{\mathbb{Q}}[m\cdot \pi^{\varphi}]\) (see flow decomposition below).

### Parametrized swap \(\pi^{\Delta Q}(r^e)\) (shipped mixture; measure TODO #17–#18)

\[
r^e_{\pi^{\Delta Q}} \equiv \mathbb E\!\left[m(\Delta Q)\cdot \pi^{\Delta Q}\right]
\]

\[
\pi^{\Delta Q}(r^e;\cdot)
=
(1-r^e)\,P_{1/2}(1-\phi_X)
+
r^e\,I(r_{1/2})(1-\phi_M)
\]

\[
\pi^\phi(p_{1/2}, r_{1/2}; \phi_X, \phi_M)
=
\phi_X P_{1/2} + \phi_M I(r_{1/2})
\]

(`Payoffs.TransactionalFeeCapture`; sum along tenor; accounting identity: capture + survival swap leg ≡ naked \(P\) / \(I\), ≤1 X96; plots `fee-capture-*-vs-*.png`.)

### Parametrized fee capture \(\pi^\phi(r_\phi^e)\) (shipped mixture; full measure TODO #17–#18)

With \(\phi = \texttt{toFeePips}(\{\phi_X,\phi_M\})\) (survival composite):

\[
r_\phi^e
=
\mathbb E\!\left[m(\phi,\Delta Q)\cdot \pi^{\Delta Q}\right]
\qquad\text{(via swap channel)}
\]

\[
r_\phi^e
=
\mathbb E\!\left[m(\phi)\cdot \pi^\phi\right]
\qquad\text{(direct fee-revenue payoff)}
\]

**Shipped shortcut** (scalar mixture weight, no `DiscountFactor` yet):

\[
r_\phi^e = \phi\cdot r^e_{\pi^{\Delta Q}}
\]

\[
\pi^\phi(r_\phi^e;\cdot)
=
(1-r_\phi^e)\,\phi_X P_{1/2}
+
r_\phi^e\,\phi_M I(r_{1/2})
\]

(`feeRevenueExpectedReturn` / `runFeeCaptureAlongTenorMixture`.)

### Ref transactional return (open — TODO #7)

\[
r^\phi = \phi\,\delta_{\mathrm{trans}}
\]

Distinct from payoff \(\pi^\phi\). Use scratchpad \(r^\phi\) / \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) notation only — **not** MEV-doc \(\Delta\pi_{\mathrm{trans}}/\pi_{\mathrm{trans}}\) (wrong). See `refs/VOLATILITY_INTRUMENTS_MEV.md` for economics only.

### Expected return split (planned — TODO #17–#21; prereq for #6)

\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV},\sigma^{e})
\]

Measure: parametric \(m(\Delta Q)\), \(m(\phi,\Delta Q)\), \(m(\phi)\) via `DiscountFactor` / `Expectation` (TODO #17–#18). \(\sigma_{IV}\) stand-in: \(\sigma_{IV}(t)=2\phi\sqrt{V(t)/L(i(t))}\) (have `TickLiquidity`; no \(V(t)\) volume yet — u88 / ξ workaround TBD).

### Flow decomposition and fee price

\[
\Delta Q = \mathbb{I}_{\Delta Q}\,\Delta Q_X + (1-\mathbb{I}_{\Delta Q})\,\Delta Q_M
\]

\[
\begin{aligned}
\Delta \pi^{\phi} &= \phi(\Theta_{\phi}; \sigma^2, \nu)\cdot \Delta Q \\
\int_{N} \Delta \pi^{\phi}\,\Delta N
&= \int_{N} \bigl(\phi(\Theta_{\phi}; \sigma^2, \nu)\cdot \Delta Q\bigr)\,\Delta N \\
\frac{\Delta \pi^{\varphi}}{\Delta N}
&\leftarrow \int_{N} \Delta \pi^{\phi}\,\Delta N \\
\frac{\Delta \pi^{\varphi}}{\Delta N}
&\equiv p_{\pi^{\varphi}}
\equiv \mathbb{E}^{\mathbb{Q}}\!\left[m\cdot \pi^{\varphi}\right]
\end{aligned}
\]

