
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
├── Payoffs/
│   ├── Payoff.hs
│   ├── CoveredCall.hs
│   ├── CashSecuredPut.hs
│   ├── RangeAccrualNote.hs
│   ├── CPMMPosition.hs
│   ├── VolatilityCall.hs
│   ├── NId.hs
│   ├── Forward.hs
│   ├── Log.hs
│   ├── VariancePortfolio.hs
│   └── TargetVega.hs
├── Pricing/
│   └── PriceDeformation.hs
├── Greeks/
│   ├── Delta.hs
│   └── Gamma.hs
├── Liquidity/
│   └── LiquidityGrid.hs
├── Volatility/
│   ├── VolatilityGrid.hs
│   ├── VolTermStructure.hs
│   ├── TickVolatility.hs
│   └── CevField.hs
├── TickPath.hs
├── SqrtGrid.hs
├── StrikeX96.hs
├── OptionRatio.hs
└── State.hs

outputs/{Pricing,Payoffs,Greeks,Liquidity,TickPath,Volatility}/
```

- `SqrtGrid`: \(\lambda=1.0001\), `TickSpacing` \(\Delta_i\in[1,200]\)
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

Hop B (in `NId.hs`, under Hop A): EVM `PanopticTokenId` `{tokenId, numLegs}` + `MintPlan` `{tokenId, positionSize}`. First inhabitant is the 4-leg all-long skeleton (per-leg `optionRatio` 4-tuple in \(1..127\), puts below \(i^\star\), calls above; \(\Delta=10\) around tick 0). `positionSize` carries \(\Delta Q_v^\star\) (id is scale-free, including the ratio shape). Dual-run: \(\pi_{96}\) from scalar \(\Delta Q_v\) equals \(\pi_{96}\) from `targetVegaFromMint`. The non-EVM `FourLegId` stub is gone. Hop C: `targetVegaFromMints` is additive. Not an on-chain `VolOrder` pack.
