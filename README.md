
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

\[
p_{1/2}^{(\mathrm{ask})} = \sqrt{1+\phi} \,p_{1/2},
\qquad
p_{1/2}^{(\mathrm{bid})} = \frac{p_{1/2}}{\sqrt{1+\phi}}
\]

Given a `Quote` with bid/ask on \(p_{1/2}\):

\[
\bigl(\phi(p_{1/2}^{(\mathrm{ask})}),\;\phi(p_{1/2}^{(\mathrm{bid})})\bigr)
\quad\Longrightarrow\quad
\phi_M \leftarrow \phi(p_{1/2}^{(\mathrm{ask})}),\;
\phi_X \leftarrow \phi(p_{1/2}^{(\mathrm{bid})})
\]

Under the fee rule:


\[
\phi \equiv 1-(1-\phi_M)(1-\phi_X)
\]


And given adaptive markup (stub): \(\phi(\Theta_\phi;\sigma^2,\nu)\) in `AdaptiveStremia`.

\[
	\begin{aligned}
		\phi \leftarrow \phi(\Theta_\phi;\sigma^2,\nu)
	\end{aligned}
\]

\[
\pi^\phi(p_{1/2}, r_{1/2}; \phi_X, \phi_M)
=
\phi_X P_{1/2} + \phi_M I(r_{1/2})
\]
\[
\pi^{\Delta Q}_{\mathrm{pay}} = P_{1/2}(1-\phi_X),
\qquad
\pi^{\Delta Q}_{\mathrm{recv}} = I(r_{1/2})(1-\phi_M)
\]

From where for any admissible expected return, it parametrizes the net-swap payoff:

\[
	\begin{aligned}
        \pi^{\Delta Q}(r^e;\cdot)
         &=  \, (1-r^e)\,\pi^{\Delta Q}_{\mathrm{pay}} \, + \, r^e\, \pi^{\Delta Q}_{\mathrm{recv}}\\
		 \\
        &= \, (1-r^e)\,P_{1/2}(1-\phi_X)
        +
        r^e\,I(r_{1/2})(1-\phi_M)

	\end{aligned}
\]


\[
\pi^\phi(r_\phi^e;\cdot)
=
(1-r_\phi^e)\,\phi_X P_{1/2}
+
r_\phi^e\,\phi_M I(r_{1/2})
\]


where for returns we have expectations:


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



\(r^e_{\pi^{\Delta Q}} \equiv \mathbb E[m(\Delta Q)\cdot \pi^{\Delta Q}]\)
\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e}, r_{\Delta Q_{\mathrm{arb}}}^{e})}\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV} - \sigma^{e})
\] (RARB)

where:

\(\sigma^{e}=\mathbb{E}^{\mathbb{Q}}[\sigma]\)

\[
\sigma_{\mathrm{IV}}(t)=2\phi\sqrt{V(t)/L(i(t))}=2\phi\,e^{u(t)/2}.
\]


\[
\sigma \, (t)=\sigma_{\mathrm{IV}}(t)
\iff
u^\star(t)=2\ln\!\Big(\frac{\sigma \, (t)}{2\phi(\,;\sigma \, (t))}\Big).
\]


geometry:

Lattice \(\kappa_j = j/N\), \(N=255\) — **encoding C**: `KappaTick` / `KappaSpacing`; B (`KappaPips`) retired. Def 45 `kappaAt (Maybe EtaX96) XiX96 LiquidityChunk` → `KappaCoordinate`.


\[
r^{\phi}(\kappa;\phi_X,\phi_M)
=
(1-\kappa)\,\phi_X + \kappa\,\phi_M
\]


and realizations:

\[
	\begin{aligned}
		r^{\phi} = \phi \cdot \delta_{\text{trans}}
	\end{aligned}
\]

Where \(\delta_{\text{trans}}\) is now pinned dimensionally as:

\[
	\begin{aligned}
		\delta_{\text{trans}} (t)\, &\equiv \Big [ \frac{u(t)}{\pi_{\text{trans}}^{\Delta Q}}\Big]
	\end{aligned}
\]





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

