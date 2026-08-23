
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

> This is corrected, the formula is for prices
\[
p^{\phi}
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


Parametric arb return (TODO #21): the \([0,1]\) measure of \(\sigma/\phi\) — vol gained per unit of markup paid, \(\sigma_{\mathrm{IV}}/\phi = 2e^{u/2}\) — through the anchor's sigmoid \(\Lambda\) (VOLATILITY_INSTRUMENTS), evaluated at \(\sigma^{e}\):

\[
	\begin{aligned}
		r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{\mathrm{IV}}, \sigma^{e}) \, &\equiv \, \Lambda\big(\gamma \, (u - u^{\star}(\sigma^{e}))\big), \qquad
		u^{\star}(\sigma^{e}) = 2\ln\!\Big(\frac{\sigma^{e}}{2\phi}\Big) \\[4pt]
		&= \, \Lambda\Big(2\gamma \, \ln \frac{\sigma_{\mathrm{IV}}}{\sigma^{e}}\Big) \qquad \text{(since } \sigma_{\mathrm{IV}} = 2\phi e^{u/2}\text{)}
	\end{aligned}
\]

\(= \tfrac12\) at \(u = u^{\star}\) (state IV-consistent); \(\to 1\) when volume/liquidity implies more vol than the markup prices (arb-rich); \(\to 0\) when the markup over-prices it. \(\gamma\) is the single free scale (absorbs \(\sqrt{\Delta t}\)). Increasing in \(\phi\) at fixed \(\sigma^{e}\) — this is the **vol-gap** channel of the arb swap leg; LVR accrual (price-arb band crossing, \(\sigma\sqrt{\Delta t}/\phi\)) is **decreasing** in \(\phi\), so \(\beta\) (arb-leg weight, #22) and \(1-g\) (realized arb volume share) remain distinct parameters. Splitter: \((r^{e}, \beta)\) ex-ante, \((r^{e}, 1-g)\) ex-post; orthogonality \(\partial\pi^{\phi}/\partial\beta = 0\), \(\partial\pi^{\mathrm{LVR}}/\partial r^{e} = 0\) (Aristotle claim, #35-style).


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

Where:
\[
	\begin{aligned}
		\delta_{\text{trans}} (t)\, &\equiv \frac{\nu_{\text{trans}}(t)}{\pi_{\text{trans}}^{\Delta Q}(t)},
		\qquad V(t)=L(i(t))\,e^{u(t)},\quad u=\ln(V/L)
	\end{aligned}
\]

\(\nu_{\text{trans}}\) derived from `refs/volume_path.gms` (\(g=\nu_{\text{trans}}/V\)); \(\pi_{\text{trans}}^{\Delta Q}\) parametrized only by exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\).


Payoff decomposition (spec `docs/superpowers/specs/2026-08-22-scratchpad-pi-varphi-lvr-decomposition-design.md`; TODO #24):

\[
\pi^{c|p} + \pi^{\mathrm{RAN}} \equiv \pi^{\varphi} \equiv \pi^{\phi} - \pi^{\mathrm{LVR}}
\]

\[
\pi^{\phi}=\pi^{\phi}\!\bigl(\pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e})\bigr),
\qquad
\pi^{\mathrm{LVR}}=\pi^{\mathrm{LVR}}\!\bigl(\pi_{\mathrm{arb}}^{\Delta Q}(r_{\mathrm{arb}}^{e})\bigr),
\qquad
\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}.
\]

\(\pi_{\mathrm{trans}}^{\Delta Q}\) exogenous (#19); \(\pi_{\mathrm{arb}}^{\Delta Q}\) from vol gap (#21). Returns: \(r^{\varphi}=r^{\phi}-r^{\mathrm{LVR}}\) (MEV \(\mathcal{N}_\pi\)).

**Roles:** GAMS \(\{\Delta Q_X,\Delta Q_M,\Delta s\}\) are **path utilities** to hit \(\delta_{\mathrm{trans}}^\*/r^{\phi}\); arb targets \(\sigma_{\mathrm{IV}}-\sigma^{e}\). Net CLMM/CPMM \(\pi^{\varphi}=f(\pi^{\phi}(\pi_{\mathrm{trans}})-\pi^{\mathrm{LVR}}(\pi_{\mathrm{arb}}))\). Roadmap: `docs/superpowers/specs/2026-08-22-scratchpad-channel-roles-roadmap.md`.


## Flow decomposition and fee price

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

