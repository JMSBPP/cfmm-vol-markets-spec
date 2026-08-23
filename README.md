
# RANGE_ACCRUAL_NOTE

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


\[
\pi^{c|p} + \pi^{\mathrm{RAN}} \equiv \pi^{\varphi} \equiv \pi^{\phi} - \pi^{\mathrm{LVR}}
\]



The **contractual** volatility payoff is as defined on VOLATILITY_INSTRUMENTS:

\[
	\begin{aligned}
		\pi^{\sigma} \, &\equiv \Delta Q_{\upsilon} \, \Big (\sigma (i(t)) \, - \, \sigma_K\Big)^{+}
	\end{aligned}
\]

And the option-replica volatility payoff is the **4-leg Panoptic position** (`MintPlan` = `PanopticTokenId` + `LiquidityChunk`), built on Uniswap liquidity positions. Objects, in the order the code constructs them:

**Liquidity chunk** (`Liquidity.LiquidityChunk.createChunk`):

\[
	\begin{aligned}
		\ell \, &\equiv \, (i^{-}, \, i^{+}, \, L), \qquad i^{-} < i^{+}, \quad 0 < L < 2^{128}, \qquad
		p_{1/2}(i) \, \equiv \, 1.0001^{\,i/2}
	\end{aligned}
\]

**\(\pi^{\varphi}\) as a function of a chunk** — the Uniswap V3 position value held by the SFPM (linear in \(L\), concave in \(p_{1/2}\)):

\[
	\begin{aligned}
		\pi^{\varphi}(\ell;\, p_{1/2}) \, &\equiv \,
		\begin{cases}
			L \, p_{1/2}^{2} \Big( \dfrac{1}{p_{1/2}(i^{-})} - \dfrac{1}{p_{1/2}(i^{+})} \Big), & p_{1/2} < p_{1/2}(i^{-}) \\[8pt]
			L \Big( 2 p_{1/2} - p_{1/2}(i^{-}) - \dfrac{p_{1/2}^{2}}{p_{1/2}(i^{+})} \Big), & p_{1/2}(i^{-}) \le p_{1/2} < p_{1/2}(i^{+}) \\[8pt]
			L \Big( p_{1/2}(i^{+}) - p_{1/2}(i^{-}) \Big), & p_{1/2} \ge p_{1/2}(i^{+})
		\end{cases}
	\end{aligned}
\]

CLMM identity (TODO #24, `CLMMPosition`): with \(\kappa_{1/2} = \sqrt{p_{1/2}(i^{-}) \, p_{1/2}(i^{+})}\), \(r = p(i^{+})/p(i^{-})\),

\[
	\begin{aligned}
		\pi^{\varphi}(\ell;\, p_{1/2}) \, &= \, L \cdot c(\kappa, r) \, \Big[ \pi^{c|p}(\kappa) + \pi^{\mathrm{RAN}}(\kappa, r) \Big]
	\end{aligned}
\]

> OPEN: the normalization \(c(\kappa,r)\) between `CLMMPosition` (unit, \(\kappa\)-normalized) and the Uniswap \(L\)-normalized form above is the CLMM identity test of TODO #24 — asserted here, not verified. The entry point is the full \(\pi^{\varphi} = \pi^{c|p}+\pi^{\mathrm{RAN}}\), **not** \(\pi^{c|p}\) alone: \(\pi^{c|p} = \min(P,K)\) is width-blind; the Panoptic `width` field enters only through \(\pi^{\mathrm{RAN}}\).

**Leg geometry** (`Volatility.VolOrder.legIntervals`): from \((i_L, i_U)\) (width/skew about \(i^{\star}\), `tickBucketFromVolOrder`) and split points \(m_P, m_C\) (`volOrderSplitPoints`):

\[
	\begin{aligned}
		(i_k^{-}, i_k^{+})_{k=0}^{3} \, &= \, \big[ i_L, m_P \big), \; \big[ m_P, i^{\star} \big), \; \big[ i^{\star}, m_C \big), \; \big[ m_C, i_U \big] \\
		\texttt{tokenType}(k) \, &= \, 0 \;\; (\text{put}), \; k \in \{0,1\}; \qquad 1 \;\; (\text{call}), \; k \in \{2,3\} \\
		\texttt{isLong}(k) \, &= \, 1 \qquad \forall k
	\end{aligned}
\]

**Per-leg option ratio and leg chunk** (`optionRatio` field, \(\mathrm{or}(k) \in \{1, \dots, 127\}\)); \(\Delta Q_{\upsilon}\) = SFPM `positionSize` = `targetVegaFromMint`:

\[
	\begin{aligned}
		L_k \, &\equiv \, \Lambda \Big( i_k^{-}, \, i_k^{+}; \; \mathrm{or}(k) \cdot \Delta Q_{\upsilon} \Big), \qquad
		\ell_k \, \equiv \, (i_k^{-}, \, i_k^{+}, \, L_k)
	\end{aligned}
\]

where \(\Lambda\) is the Uniswap amount\(\to\)liquidity map over the leg range (token0 amount for calls, token1 for puts). \(\Delta Q_{\upsilon}\) scales every leg linearly.

**4-leg replica.** A long Panoptic leg pays the OTM mint value of its chunk minus the cost to return that chunk's liquidity at the current price:

\[
	\begin{aligned}
		\hat{\pi^{\sigma}}(p_{1/2}) \, &\equiv \, \sum_{k=0}^{3} \, \Big[ \pi^{\varphi}\big(\ell_k;\, p^{\star}_{1/2}\big) \, - \, \pi^{\varphi}\big(\ell_k;\, p_{1/2}\big) \Big]
	\end{aligned}
\]

Legs are OTM at \(p^{\star}\), so \(\pi^{\varphi}(\ell_k; p^{\star}_{1/2})\) is a constant per leg: \(L_k \big(p_{1/2}(i_k^{+}) - p_{1/2}(i_k^{-})\big)\) for puts, \(L_k \, p^{\star} \big(1/p_{1/2}(i_k^{-}) - 1/p_{1/2}(i_k^{+})\big)\) for calls. This is the bridge \(\hat{\pi^{\sigma}} = f(\pi^{\varphi})\): \(f\) is \(x \mapsto \sum_k [\mathrm{const}_k - x_k]\) on the leg vector \(\big(\pi^{\varphi}(\ell_k)\big)_k\), convex in \(p_{1/2}\) because each \(-\pi^{\varphi}(\ell_k)\) is. Substituting \(\pi^{\varphi} = \pi^{\phi} - \pi^{\mathrm{LVR}}\):

\[
	\begin{aligned}
		\hat{\pi^{\sigma}} \, &= \, \sum_{k=0}^{3} \, \Big[ \pi^{\mathrm{LVR}}(\ell_k) \, - \, \pi^{\phi}(\ell_k) \Big] \, + \, \sum_{k=0}^{3} \pi^{\varphi}\big(\ell_k;\, p^{\star}_{1/2}\big)
	\end{aligned}
\]

Long vol = LVR extracted from the borrowed chunks minus the fees forgone (streamia) on them.

Remarks (not definitions): (i) shipped Hop A/B \(\Delta Q_{\upsilon}\big[N_{\mathrm{id}}(F - \mathrm{Log}) + R\big]\) (`VariancePortfolio`) is the Carr–Madan continuum limit of the 4-leg sum; (ii) MEV \(\sum_i L(i)\,\pi^{\varphi}(i)\) is the **short** side of this same book, hence not ground truth for \(\hat{\pi^{\sigma}}\). Gaps in code: `volOrderToMintPlan` builds one envelope chunk \((i_L, i_U, \Delta Q_{\upsilon})\), not four \(\ell_k\); \(\Lambda\) and \(\mathrm{or}(k) \to L_k\) are not implemented (`OptionRatio.hs` TODO).

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

