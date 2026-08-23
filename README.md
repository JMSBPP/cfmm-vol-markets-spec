
# RANGE_ACCRUAL_NOTE

The sqrt-coordinate range payoff is


\[
	\begin{aligned}
		\pi^{\text{RA}}(k_{1/2}, r; p_{1/2}) =
			\begin{cases}
		0, & p_{1/2} < k_{1/2}/\sqrt{r}, \\[4pt]
		\dfrac{2\cdot p_{1/2} k_{1/2} \sqrt{r} - p_{1/2}^2r - k_{1/2}^2}{r-1}, & k_{1/2}/\sqrt{r} \le p_{1/2} < k_{1/2}, \\[8pt]
		\dfrac{2p_{1/2}k_{1/2}\sqrt{r} - p_{1/2}^2 - k_{1/2}^2r}{r-1}, & k_{1/2} \le p_{1/2} < k_{1/2}\sqrt{r}, \\[8pt]
		0, & p_{1/2} \ge k_{1/2}\sqrt{r}.
			\end{cases}
	\end{aligned}
\]


\[
\pi^{c|p} + \pi^{\mathrm{RAN}} \equiv \pi^{\varphi} \equiv \pi^{\phi} - \pi^{\mathrm{LVR}}
\]



The **contractual** volatility payoff is as defined on VOLATILITY_INSTRUMENTS:

\[
	\begin{aligned}
		\pi^{\sigma} \, &\equiv \Delta Q_{\upsilon} \, \Big (\sigma (i(t)) \, - \, \sigma_K\Big)^{+}
	\end{aligned}
\]

And the option-replica volatility payoff is the **4-leg Panoptic position** 

**Liquidity chunk** (`Liquidity.LiquidityChunk.createChunk`); \(\mathcal{LC}\) is the chunk, \(\ell\) is reserved for the LDF below:

\[
	\begin{aligned}
		\mathcal{LC} \, &\equiv \, (i^{-}, \, i^{+}, \, L), \qquad i^{-} < i^{+}, \quad 0 < L < 2^{128}, \qquad
		p_{1/2}(i) \, \equiv \, 1.0001^{\,i/2} \\
		k_{1/2}(i^{-}, i^{+}) \, &\equiv \, \sqrt{p_{1/2}(i^{-}) \, p_{1/2}(i^{+})}, \qquad
		r(i^{-}, i^{+}) \, \equiv \, \frac{p(i^{+})}{p(i^{-})} \, = \, 1.0001^{\,i^{+} - i^{-}}
	\end{aligned}
\]

Unit chunk at tick \(i\) (tick spacing \(\Delta_i\); units handled on the EVM directly, \(1e18\) = one unit of \(L\)):

\[
	\begin{aligned}
		\mathrm{Id}_i[\mathcal{LC}] \, &\equiv \, (i, \, i + \Delta_i, \, 1e18)
	\end{aligned}
\]

\(r(i^{-},i^{+})\) is the width ratio. The 7-bit per-leg field \(\mathrm{or}(\mathrm{leg})\) below is a different object (size multiplier) and keeps its own symbol.

**\(\pi^{\varphi}\) of a chunk** — the Uniswap V3 position principal held by the SFPM (`PositionValue.principal`; linear in \(L\), concave in \(p_{1/2}\)):

\[
	\begin{aligned}
		\pi^{\varphi}(\mathcal{LC};\, p_{1/2}) \, &\equiv \,
		\begin{cases}
			L \, p_{1/2}^{2} \Big( \dfrac{1}{p_{1/2}(i^{-})} - \dfrac{1}{p_{1/2}(i^{+})} \Big), & p_{1/2} < p_{1/2}(i^{-}) \\[8pt]
			L \Big( 2 p_{1/2} - p_{1/2}(i^{-}) - \dfrac{p_{1/2}^{2}}{p_{1/2}(i^{+})} \Big), & p_{1/2}(i^{-}) \le p_{1/2} < p_{1/2}(i^{+}) \\[8pt]
			L \Big( p_{1/2}(i^{+}) - p_{1/2}(i^{-}) \Big), & p_{1/2} \ge p_{1/2}(i^{+})
		\end{cases}
	\end{aligned}
\]

**Tick additivity.** A chunk is a sum of unit chunks:

\[
	\begin{aligned}
		\pi^{\varphi}(\mathcal{LC};\, p_{1/2}) \, &= \, \frac{L}{1e18} \sum_{i = i^{-}}^{i^{+} - \Delta_i} \pi^{\varphi}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big)
	\end{aligned}
\]


\[
	\begin{aligned}
		\pi^{\varphi}(\mathcal{LC}, \ell;\, p_{1/2}) \, &\equiv \, \frac{\bar L}{1e18} \sum_{i} \ell(i) \, \pi^{\varphi}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big), \qquad
		\bar L \, = \, L \, \frac{i^{+} - i^{-}}{\Delta_i} \\[4pt]
		\pi^{\varphi}(\mathcal{LC};\, p_{1/2}) \, &\equiv \, \pi^{\varphi}(\mathcal{LC}, \ell_{U};\, p_{1/2}), \qquad
		\ell_{U}(i) \, = \, \frac{\mathbb{1}[\, i^{-} \le i < i^{+} \,]}{(i^{+} - i^{-})/\Delta_i}
	\end{aligned}
\]

\[
	\begin{aligned}
		\ell(\ell_{\mathcal{G}}, \omega;\, i) \, &\equiv \, \sum_{g} \omega_g \, \ell_{\mathcal{G}}(\iota_g;\, i \mid \xi^{\star}), \qquad \omega_g \ge 0, \; \sum_g \omega_g = 1, \quad \ell(i) \ge 0, \; \sum_i \ell(i) = 1
	\end{aligned}
\]


\[
	\begin{aligned}
		\pi^{\varphi}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big) \, &\overset{?}{=} \, L_{\Delta_i} \, \Big[ \pi^{c|p}\big(k_{1/2}(i, i+\Delta_i)\big) + \pi^{\mathrm{RAN}}\big(k_{1/2}(i, i+\Delta_i), \, r(i, i+\Delta_i)\big) \Big]
	\end{aligned}
\]

> DESIGN CLAIM — to be proved (Aristotle / Lean), not asserted. \(L_{\Delta_i}\) is a single liquidity constant per tick spacing (not a function of the range), which is the whole content of the claim; if it fails, the `CLMMPosition` unit payoff and the Uniswap unit payoff differ by more than scale and #24's CLMM identity test is the place that surfaces it. The entry point is the full \(\pi^{c|p} + \pi^{\mathrm{RAN}}\), **not** \(\pi^{c|p}\) alone: \(\pi^{c|p} = \min(P, K)\) is width-blind; width enters only through \(\pi^{\mathrm{RAN}}\).

**Leg geometry** (`Volatility.VolOrder.legIntervals`): from \((i_L, i_U)\) (width/skew about \(i^{\star}\), `tickBucketFromVolOrder`) and split points \(m_P, m_C\) (`volOrderSplitPoints`):

\[
	\begin{aligned}
		(i_{\mathrm{leg}}^{-}, i_{\mathrm{leg}}^{+})_{\mathrm{leg}=0}^{3} \, &= \, \big[ i_L, m_P \big), \; \big[ m_P, i^{\star} \big), \; \big[ i^{\star}, m_C \big), \; \big[ m_C, i_U \big] \\
		\texttt{tokenType}(\mathrm{leg}) \, &= \, 0 \;\; (\text{put}), \; \mathrm{leg} \in \{0,1\}; \qquad 1 \;\; (\text{call}), \; \mathrm{leg} \in \{2,3\} \\
		\texttt{isLong}(\mathrm{leg}) \, &= \, 1 \qquad \forall \, \mathrm{leg}
	\end{aligned}
\]

**Per-leg option ratio and leg chunk** (`optionRatio` field, \(\mathrm{or}(\mathrm{leg}) \in \{1, \dots, 127\}\)); \(\Delta Q_{\upsilon}\) = SFPM `positionSize` = `targetVegaFromMint`:
\[
	\begin{aligned}
		L_{\mathrm{leg}} \, &\equiv \,
		\begin{cases}
			\dfrac{\mathrm{or}(\mathrm{leg}) \cdot \Delta Q_{\upsilon}}{p_{1/2}(i_{\mathrm{leg}}^{+}) \, - \, p_{1/2}(i_{\mathrm{leg}}^{-})}, & \texttt{tokenType}(\mathrm{leg}) = 0 \;\; (\text{put; notional in token1}) \\[10pt]
			\dfrac{\mathrm{or}(\mathrm{leg}) \cdot \Delta Q_{\upsilon}}{1/p_{1/2}(i_{\mathrm{leg}}^{-}) \, - \, 1/p_{1/2}(i_{\mathrm{leg}}^{+})}, & \texttt{tokenType}(\mathrm{leg}) = 1 \;\; (\text{call; notional in token0})
		\end{cases} \\[6pt]
		\mathcal{LC}_{\mathrm{leg}} \, &\equiv \, (i_{\mathrm{leg}}^{-}, \, i_{\mathrm{leg}}^{+}, \, L_{\mathrm{leg}})
	\end{aligned}
\]

These are the Uniswap `getLiquidityForAmount1` / `getLiquidityForAmount0` inversions over the leg range (`PanopticMath.getLiquidityChunk`: `amount = positionSize · optionRatio`). \(\Delta Q_{\upsilon}\) scales every leg linearly.

**4-leg replica.** A long Panoptic leg pays the OTM mint value of its chunk minus the cost to return that chunk's liquidity at the current price:

\[
	\begin{aligned}
		\hat{\pi^{\sigma}}(p_{1/2}) \, &\equiv \, \sum_{\mathrm{leg}=0}^{3} \, \Big[ \pi^{\varphi}\big(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}\big) \, - \, \pi^{\varphi}\big(\mathcal{LC}_{\mathrm{leg}};\, p_{1/2}\big) \Big]
	\end{aligned}
\]

Legs are OTM at \(p^{\star}\), so \(\pi^{\varphi}(\mathcal{LC}_{\mathrm{leg}}; p^{\star}_{1/2})\) is a constant per leg: \(L_{\mathrm{leg}} \big(p_{1/2}(i_{\mathrm{leg}}^{+}) - p_{1/2}(i_{\mathrm{leg}}^{-})\big)\) for puts, \(L_{\mathrm{leg}} \, p^{\star} \big(1/p_{1/2}(i_{\mathrm{leg}}^{-}) - 1/p_{1/2}(i_{\mathrm{leg}}^{+})\big)\) for calls. 

Substituting \(\pi^{\varphi} = \pi^{\phi} - \pi^{\mathrm{LVR}}\):

\[
	\begin{aligned}
		\hat{\pi^{\sigma}} \, &= \, \sum_{\mathrm{leg}=0}^{3} \, \Big[ \pi^{\mathrm{LVR}}(\mathcal{LC}_{\mathrm{leg}}) \, - \, \pi^{\phi}(\mathcal{LC}_{\mathrm{leg}}) \Big] \, + \, \sum_{\mathrm{leg}=0}^{3} \pi^{\varphi}\big(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}\big)
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
├── Greeks
│   ├── Delta.hs
│   ├── Gamma.hs
│   ├── Theta.hs
│   └── Vega.hs
├── Lib.hs
├── Liquidity
│   ├── LiquidityChunk.hi
│   ├── LiquidityChunk.hs
│   ├── LiquidityChunk.o
│   ├── LiquidityDensity.hs
│   ├── LiquidityGrid.hi
│   ├── LiquidityGrid.hs
│   ├── LiquidityGrid.o
│   ├── TickLiquidity.hi
│   ├── TickLiquidity.hs
│   └── TickLiquidity.o
├── OptionRatio.hs
├── Panoptic
│   ├── MintPlan.hs
│   └── NId.hs
├── Payoffs
│   ├── CashSecuredPut.hs
│   ├── CLMMPosition.hs
│   ├── CoveredCall.hs
│   ├── Forward.hs
│   ├── Linear.hs
│   ├── Log.hs
│   ├── Payoff.hs
│   ├── RangeAccrualNote.hs
│   ├── Return.hs
│   ├── Savings.hs
│   ├── Swap.hs
│   ├── TransactionalFeeCapture.hs
│   ├── VariancePortfolio.hs
│   └── VolatilityCall.hs
├── Plotting
│   ├── PlotInterest.hs
│   ├── PlotSqrt.hs
│   └── PlotUtils.hs
├── Pricing
│   ├── AdaptiveStremia.hs
│   ├── ExpectedReturn.hs
│   ├── FeeStructure.hs
│   ├── InterestPriceMap.hs
│   ├── InterestSqrt.hs
│   ├── MarkUpStructure.hs
│   ├── PriceDeformation.hi
│   ├── PriceDeformation.hs
│   ├── PriceDeformation.o
│   └── Stremia.hs
├── SqrtGrid.hi
├── SqrtGrid.hs
├── SqrtGrid.o
├── State.hs
├── StrikeX96.hs
├── TargetVega.hs
├── TickPath.hs
├── Trading
│   ├── KappaCoordinate.hi
│   ├── KappaCoordinate.hs
│   ├── KappaCoordinate.o
│   ├── PriceImpact.hs
│   └── Quote.hs
└── Volatility
    ├── CevField.hs
    ├── ExpectedVolatility.hs
    ├── ImpliedVolatility.hs
    ├── TickVolatility.hs
    ├── VolatilityGrid.hi
    ├── VolatilityGrid.hs
    ├── VolatilityGrid.o
    ├── VolOrder.hs
    └── VolTermStructure.hs


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

where for returns we have expectations, where expectd transactional return is estimated /computed fro =m exogenous transactional demand inputs :


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


Weights in (RARB), both in \([0,1]\):

\[
	\begin{aligned}
		\partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e},\, r_{\Delta Q_{\mathrm{arb}}}^{e})} \, &\equiv \, \frac{\partial \, r_{\Delta Q}^{e}}{\partial \, r_{\Delta Q_{\mathrm{arb}}}^{e}}\bigg|_{r_{\Delta Q_{\mathrm{trans}}}^{e}}
		\qquad \text{(ex-ante weight of the arb leg in the net-swap return; TODO \#22 — a definition by role, its formula is the open item)} \\[4pt]
		\Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big] \, &\in [0,1], \qquad \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] = 1 - \Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big]
		\qquad \text{(ex-post transactional share of volume, an \textbf{atomic given value} — brackets mean it is read, not computed as a ratio; `refs/volume_path.gms`, TODO \#23)}
	\end{aligned}
\]

\(\partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e},\, r_{\Delta Q_{\mathrm{arb}}}^{e})}\) is the ex-ante counterpart of the realized \(\Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big]\). Note \(\Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big]\) \(\ne \delta_{\mathrm{trans}}\): the bracket is a share of total volume, \(\delta_{\mathrm{trans}} = \nu_{\mathrm{trans}}/\pi^{\Delta Q}_{\mathrm{trans}}\) is turnover of the transactional leg; only the bracket carries the trans/arb split.

Parametric arb return (TODO #21): the \([0,1]\) measure of \(\sigma/\phi\) — vol gained per unit of markup paid, \(\sigma_{\mathrm{IV}}/\phi = 2e^{u/2}\) — through the anchor's sigmoid \(\Lambda\) (VOLATILITY_INSTRUMENTS), evaluated at \(\sigma^{e}\):

\[
	\begin{aligned}
		r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{\mathrm{IV}}, \sigma^{e}) \, &\equiv \, \Lambda\big(\gamma \, (u - u^{\star}(\sigma^{e}))\big), \qquad
		u^{\star}(\sigma^{e}) = 2\ln\!\Big(\frac{\sigma^{e}}{2\phi}\Big) \\[4pt]
		&= \, \Lambda\Big(2\gamma \, \ln \frac{\sigma_{\mathrm{IV}}}{\sigma^{e}}\Big) \qquad \text{(since } \sigma_{\mathrm{IV}} = 2\phi e^{u/2}\text{)}
	\end{aligned}
\]

\(= \tfrac12\) at \(u = u^{\star}\) (state IV-consistent); \(\to 1\) when volume/liquidity implies more vol than the markup prices (arb-rich); \(\to 0\) when the markup over-prices it. \(\gamma\) is the single free scale (absorbs \(\sqrt{\Delta t}\)). Increasing in \(\phi\) at fixed \(\sigma^{e}\) — this is the **vol-gap** channel of the arb swap leg; LVR accrual (price-arb band crossing, \(\sigma\sqrt{\Delta t}/\phi\)) is **decreasing** in \(\phi\), so \(\partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e},\, r_{\Delta Q_{\mathrm{arb}}}^{e})}\) (arb-leg weight, #22) and \(\Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big]\) (realized arb volume share) remain distinct parameters. Splitter: \((r^{e}, \partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e},\, r_{\Delta Q_{\mathrm{arb}}}^{e})})\) ex-ante, \((r^{e}, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big])\) ex-post; orthogonality \(\partial\pi^{\phi}/\partial\,\partial_{(r_{\Delta Q_{\mathrm{trans}}}^{e},\, r_{\Delta Q_{\mathrm{arb}}}^{e})} = 0\), \(\partial\pi^{\mathrm{LVR}}/\partial r^{e} = 0\) (Aristotle claim, #35-style).



Net-swap payoff by flow type, then by token side (two nested \([0,1]\) weights — the bracket is the flow-type share, \(r^{e}\) the token-side weight; neither replaces the other):

\[
	\begin{aligned}
		\pi^{\Delta Q} \, &= \, \Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big] \, \pi^{\Delta Q}_{\mathrm{trans}}\big(r_{\Delta Q_{\mathrm{trans}}}^{e}\big) \, + \, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] \, \pi^{\Delta Q}_{\mathrm{arb}}\big(r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{\mathrm{IV}}, \sigma^{e})\big), \qquad \Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big] + \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] = 1
	\end{aligned}
\]

For solving for the tax the parameter is \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] read directly: \(\tau_{\mathrm{MEV}}\) moves the arb share and \(\nu_{\mathrm{arb}}\), not \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) — so \(\pi^{\phi}\) (token side + volume) and \(\pi^{\mathrm{LVR}}\) (arb share) separate, and the vol-gap parametrization \(r_{\Delta Q_{\mathrm{arb}}}^{e}\) stays as the inner weight of the arb leg.



Where:
\[
	\begin{aligned}
		\delta_{\text{trans}} (t)\, &\equiv \frac{\nu_{\text{trans}}(t)}{\pi_{\text{trans}}^{\Delta Q}(t)},
		\qquad V(t)=L(i(t))\,e^{u(t)},\quad u=\ln(V/L)
	\end{aligned}
\]

\(\nu_{\text{trans}}\) derived from `refs/volume_path.gms` (\Big[\tfrac{\nu_{\mathrm{trans}}}{\nu}\Big] read as an atomic given value); \(\pi_{\text{trans}}^{\Delta Q}\) parametrized only by exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\).


Payoff decomposition (spec `docs/superpowers/specs/2026-08-22-scratchpad-pi-varphi-lvr-decomposition-design.md`; TODO #24):

\[
\pi^{c|p} + \pi^{\mathrm{RAN}} \equiv \pi^{\varphi} \equiv \pi^{\phi} - \pi^{\mathrm{LVR}}
\]

Objective (anchor \(e^{\sigma} = |\pi^{\sigma} - \hat{\pi^{\sigma}}|\)): \(\pi^{\sigma} = \Delta Q_{\upsilon}(\sigma - \sigma_K)^{+}\) is \(\tau_{\mathrm{MEV}}\)-free, so all \(\tau_{\mathrm{MEV}}\) dependence of \(e^{\sigma}\) runs through the replica, along one explicit chain:

\[
	\begin{aligned}
		\tau_{\mathrm{MEV}} \;\to\; \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big](\tau_{\mathrm{MEV}}) \;\to\; \pi^{\mathrm{LVR}}(\mathcal{LC}_{\mathrm{leg}}) \;\to\; \pi^{\varphi}(\mathcal{LC}_{\mathrm{leg}}) = \pi^{\phi} - \pi^{\mathrm{LVR}} \;\to\; \hat{\pi^{\sigma}} = \sum_{\mathrm{leg}=0}^{3} \Big[ \pi^{\varphi}(\mathcal{LC}_{\mathrm{leg}}; p^{\star}_{1/2}) - \pi^{\varphi}(\mathcal{LC}_{\mathrm{leg}}; p_{1/2}) \Big] 
	\end{aligned}
\]

\[
	\begin{aligned}
	\inf_{\tau_{\mathrm{MEV}}} \, e^{\sigma}(\tau_{\mathrm{MEV}}) \, &= \, \inf_{\tau_{\mathrm{MEV}}} \, \Big| \pi^{\sigma} - \hat{\pi^{\sigma}}\big(\Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big](\tau_{\mathrm{MEV}})\big) \Big|
	\end{aligned}

\]

LVR connector — volume share only, rate-only (no level \(\nu\) is observed in this model; only \(u = \ln(V/L)\), the atomic shares, and returns). LVR per unit of arb share is the price gap captured crossing the fee band; its vol-over-fee argument is read from state as \(\sigma_{\mathrm{IV}}/\phi = 2e^{u/2}\), so it is a function of \((u, \phi)\) and the chunk geometry, not of which token the arb delivers. With the anchor's \(\lambda_{\mathrm{ARB}}\) as a return and the MEV normalizer \(\mathcal{N}_\pi\):

\[
	\begin{aligned}
		r^{\mathrm{LVR}}(\mathcal{LC}_{\mathrm{leg}}) \, &= \, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] \, \lambda_{\mathrm{ARB}}\big(u, \phi;\, \mathcal{LC}_{\mathrm{leg}}\big), \qquad
		\pi^{\mathrm{LVR}} \, = \, \mathcal{N}_\pi^{-1} \, r^{\mathrm{LVR}}, \qquad
		r^{\varphi} \, = \, r^{\phi} - r^{\mathrm{LVR}}
	\end{aligned}
\]

The return parameter \(r_{\Delta Q_{\mathrm{arb}}}^{e}\) does not appear: it parametrizes \(\pi^{\Delta Q}_{\mathrm{arb}}\) (what the LP is left holding after the arb swap) and enters the replica only through the legs' token composition (the \(p^{\star}\) constants) — second order for \(e^{\sigma}\). For the tax exercise one parameter suffices: the chain above never touches \(r_{\Delta Q_{\mathrm{arb}}}^{e}\); hold it at its IV-consistent value \(\tfrac12\) (or the observed value) and optimize over \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] alone. Two parameters are the model (they make \(\pi^{\phi}\) and \(\pi^{\mathrm{LVR}}\) orthogonal), one parameter is the tax FOC.

\[
\pi^{\phi}=\pi^{\phi}\!\bigl(\pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e})\bigr),
\qquad
\pi^{\mathrm{LVR}}=\pi^{\mathrm{LVR}}\!\bigl(\pi_{\mathrm{arb}}^{\Delta Q}(r_{\mathrm{arb}}^{e})\bigr),
\qquad
\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}.
\]



