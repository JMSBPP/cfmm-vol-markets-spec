# PRICE_GRID

Fee-deformed sqrt-price quotes; the chunk bounds are identified with them: \(p_{1/2}^{(\mathrm{bid})} \equiv p_{1/2}^{(\mathrm{bid})}\), \(p_{1/2}^{(\mathrm{ask})} \equiv p_{1/2}^{(\mathrm{ask})}\), and bid/ask notation is used throughout.

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
		p_{1/2}(i) \, \equiv \, 1.0001^{\,i/2}, \quad p_{1/2}^{(\mathrm{bid})} \equiv p_{1/2}(i^{-}), \; p_{1/2}^{(\mathrm{ask})} \equiv p_{1/2}(i^{+}) \\
		k_{1/2}(i^{-}, i^{+}) \, &\equiv \, \sqrt{p_{1/2}^{(\mathrm{bid})} \, p_{1/2}^{(\mathrm{ask})}}, \qquad
		r(i^{-}, i^{+}) \, \equiv \, \frac{p_{1/2}^{(\mathrm{ask})}}{p_{1/2}^{(\mathrm{bid})}} \, = \, 1.0001^{\,(i^{+} - i^{-})/2} \qquad \text{(sqrt-price ratio — the } r \text{ of } \pi^{\mathrm{RAN}}\text{)}
	\end{aligned}
\]

Unit chunk at tick \(i\) (tick spacing \(\Delta_i\); units handled on the EVM directly, \(1e18\) = one unit of \(L\)):

\[
	\begin{aligned}
		\mathrm{Id}_i[\mathcal{LC}] \, &\equiv \, (i, \, i + \Delta_i, \, 1e18)
	\end{aligned}
\]

\(r(i^{-},i^{+})\) is the width ratio. The 7-bit per-leg field \(\mathrm{or}(\mathrm{leg})\) below is a different object (size multiplier) and keeps its own symbol.

**\(\pi^{\Delta Q_X}\) of a chunk (the bare principal, anchor Definition 49)** — the Uniswap V3 position principal held by the SFPM (`PositionValue.principal`; linear in \(L\), concave in \(p_{1/2}\)):

Glyph (anchor Definition 49, user-ruled 2026-08-24): \(\pi^{\Delta Q_X}\) is the **bare principal** (`PositionValue.principal`); \(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\) stays the **net LP accrual**. \(\mathrm{amount}_0 \equiv \Delta Q_M^L\) (money leg), \(\mathrm{amount}_1 \equiv \Delta Q_X^L\) (asset leg). Lean: `LadderPrincipal.principal`, `amount0`, `amount1`.


\[
	\begin{aligned}
		\pi^{\Delta Q_X}(\mathcal{LC};\, p_{1/2}) \, &\equiv \,
		\begin{cases}
			L \, p_{1/2}^{2} \Big( \dfrac{1}{p_{1/2}^{(\mathrm{bid})}} - \dfrac{1}{p_{1/2}^{(\mathrm{ask})}} \Big), & p_{1/2} < p_{1/2}^{(\mathrm{bid})} \\[8pt]
			L \Big( 2 p_{1/2} - p_{1/2}^{(\mathrm{bid})} - \dfrac{p_{1/2}^{2}}{p_{1/2}^{(\mathrm{ask})}} \Big), & p_{1/2}^{(\mathrm{bid})} \le p_{1/2} < p_{1/2}^{(\mathrm{ask})} \\[8pt]
			L \Big( p_{1/2}^{(\mathrm{ask})} - p_{1/2}^{(\mathrm{bid})} \Big), & p_{1/2} \ge p_{1/2}^{(\mathrm{ask})}
		\end{cases}
	\end{aligned}
\]

**Tick additivity.** A chunk is a sum of unit chunks:

\[
	\begin{aligned}
		\pi^{\Delta Q_X}(\mathcal{LC};\, p_{1/2}) \, &= \, \frac{L}{1e18} \sum_{i = i^{-}}^{i^{+} - \Delta_i} \pi^{\Delta Q_X}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big)
	\end{aligned}
\]


\[
	\begin{aligned}
		\pi^{\Delta Q_X}(\mathcal{LC}, \ell;\, p_{1/2}) \, &\equiv \, \frac{\bar L}{1e18} \sum_{i} \ell(i) \, \pi^{\Delta Q_X}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big), \qquad
		\bar L \, = \, L \, \frac{i^{+} - i^{-}}{\Delta_i} \\[4pt]
		\pi^{\Delta Q_X}(\mathcal{LC};\, p_{1/2}) \, &\equiv \, \pi^{\Delta Q_X}(\mathcal{LC}, \ell_{U};\, p_{1/2}), \qquad
		\ell_{U}(i) \, = \, \frac{\mathbb{1}[\, i^{-} \le i < i^{+} \,]}{(i^{+} - i^{-})/\Delta_i}
	\end{aligned}
\]

\[
	\begin{aligned}
		\ell(\ell_{\mathcal{G}}, \omega;\, i) \, &\equiv \, \sum_{g} \omega_g \, \ell_{\mathcal{G}}(\iota_g;\, i \mid \xi^{\star}), \qquad \omega_g \ge 0, \; \sum_g \omega_g = 1, \quad \ell(i) \ge 0, \; \sum_i \ell(i) = 1
	\end{aligned}
\]


> Amount 0 is \Delta Q_X^L
\[
	\begin{aligned}
		\pi^{\Delta Q_X}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big) \, &= \, \mathrm{amount}_0\big(\mathrm{Id}_i[\mathcal{LC}]\big) \, \Big[ \pi^{c|p}\big(k_{1/2}(i, i+\Delta_i)\big) + \pi^{\mathrm{RAN}}\big(k_{1/2}(i, i+\Delta_i), \, r(i, i+\Delta_i)\big) \Big] \\[4pt]
		\mathrm{amount}_0\big(\mathrm{Id}_i[\mathcal{LC}]\big) \, &= \, 1e18 \, \Big( \frac{1}{p_{1/2}^{(\mathrm{bid})}} - \frac{1}{p_{1/2}^{(\mathrm{ask})}} \Big)
	\end{aligned}
\]


> We need to minimze prose and follow notation standards and avoid introducing new vars like a / b
Proof sketch: with \(a = p^{(\mathrm{bid})}_{1/2}\), \(b = p^{(\mathrm{ask})}_{1/2}\), \(k_{1/2}\sqrt r = b\), \(k_{1/2}^2 = ab\), both RAN arms reduce to \((2pb - p^2 - ab)/(r-1)\) while the in-range principal is \((2pb - p^2 - ab)/b\); below range both are \(\propto p^2\); above, \(b - a\) vs \(ab\). The ratio is \(1/a - 1/b\) in all three pieces. So the normalization is the unit chunk's **token0 amount** (`getAmount0ForLiquidity`), a function of \((i, \Delta_i)\) — **not** one constant per tick spacing as first claimed — and `CLMMPosition` is the LP payoff per unit of token0 notional. The identity requires \(r\) to be the sqrt-price ratio (fixed above). The entry point is the full \(\pi^{c|p} + \pi^{\mathrm{RAN}}\), **not** \(\pi^{c|p}\) alone: \(\pi^{c|p} = \min(P, K)\) is width-blind; width enters only through \(\pi^{\mathrm{RAN}}\). Aristotle transcription still owed (#35, gated on the Lean workspace) — the hand proof is elementary algebra on three pieces.

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
			\dfrac{\mathrm{or}(\mathrm{leg}) \cdot \Delta Q_{\upsilon}}{p_{1/2}^{(\mathrm{ask})}(\mathrm{leg}) \, - \, p_{1/2}^{(\mathrm{bid})}(\mathrm{leg})}, & \texttt{tokenType}(\mathrm{leg}) = 0 \;\; (\text{put; notional in token1}) \\[10pt]
			\dfrac{\mathrm{or}(\mathrm{leg}) \cdot \Delta Q_{\upsilon}}{1/p_{1/2}^{(\mathrm{bid})}(\mathrm{leg}) \, - \, 1/p_{1/2}^{(\mathrm{ask})}(\mathrm{leg})}, & \texttt{tokenType}(\mathrm{leg}) = 1 \;\; (\text{call; notional in token0})
		\end{cases} \\[6pt]
		\mathcal{LC}_{\mathrm{leg}} \, &\equiv \, (i_{\mathrm{leg}}^{-}, \, i_{\mathrm{leg}}^{+}, \, L_{\mathrm{leg}})
	\end{aligned}
\]

These are the Uniswap `getLiquidityForAmount1` / `getLiquidityForAmount0` inversions over the leg range (`PanopticMath.getLiquidityChunk`: `amount = positionSize · optionRatio`). The numeraire of `positionSize · optionRatio` is the leg's `asset` bit (independent of put/call): this model sets **`asset = 1` (token1) on all four legs** so the four notionals share one basis (`Panoptic.NId.addAsset`, `Panoptic.LegChunk.legLiquidity` with the contract's polarity `0 → Amount0, 1 → Amount1`; PR #62). Arithmetic follows the staged `mulDiv` forms of `Math.sol`; intermediate widths in `docs/BITWIDTHS.md`. Each \(\mathcal{LC}_{\mathrm{leg}}\) is a `CLMMPosition` via `fromChunk` — every `CLMMPosition` is chunk-constructed (location \(k_{1/2}, r\) and scale \(\mathrm{amount}_0\) both from the chunk). \(\Delta Q_{\upsilon}\) scales every leg linearly.

**4-leg replica.** A long Panoptic leg pays the OTM mint value of its chunk minus the cost to return that chunk's liquidity at the current price:

\[
	\begin{aligned}
		\hat{\pi^{\sigma}}(p_{1/2}) \, &\equiv \, \sum_{\mathrm{leg}=0}^{3} \, \Big[ \pi^{\Delta Q_X}\big(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}\big) \, - \, \pi^{\Delta Q_X}\big(\mathcal{LC}_{\mathrm{leg}};\, p_{1/2}\big) \Big]
	\end{aligned}
\]

Per-leg mint value \(H_{\mathrm{leg}}(p_{1/2})\), valued in token1 at the current price: puts (token1 received) \(H = \mathrm{amount}_1(\mathcal{LC}_{\mathrm{leg}})\), a constant; calls (token0 received) \(H = p_{1/2}^{2}\,\mathrm{amount}_0(\mathcal{LC}_{\mathrm{leg}})\), which floats with \(p\) — so \(\hat{\pi^{\sigma}} = \sum_{\mathrm{leg}} [H_{\mathrm{leg}}(p_{1/2}) - \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}}; p_{1/2})]\), \(= 0\) at \(p^{\star}\) (all legs OTM) and \(\ge 0\) (each \(-\pi^{\varphi}\) convex). Code: `Panoptic.LegChunk` (\(\mathcal{LC}_{\mathrm{leg}}\), \(\mathrm{or}(\mathrm{leg}) \to L_{\mathrm{leg}}\)), `Payoffs.VolatilityReplica.fourLegReplica`. 

Reading the current principal \(\pi^{\Delta Q_X}\) through its net-accrual decomposition (on-chain `total = principal + fees`; \(\pi^{\varphi} = \pi^{\phi} - \pi^{\mathrm{LVR}}\), LVR being the principal's concavity gap to the rebalancing benchmark):

\[
	\begin{aligned}
		\hat{\pi^{\sigma}} \, &= \, \sum_{\mathrm{leg}=0}^{3} \, \Big[ \pi^{\mathrm{LVR}}(\mathcal{LC}_{\mathrm{leg}}) \, - \, \pi^{\phi}(\mathcal{LC}_{\mathrm{leg}}) \Big] \, + \, \sum_{\mathrm{leg}=0}^{3} \pi^{\Delta Q_X}\big(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}\big)
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

Objective (anchor \(e^{\sigma} = |\pi^{\sigma} - \hat{\pi^{\sigma}}|\); **\(\tau_{\mathrm{MEV}}\) and the signed transfer \(s\) (TODO #31) are both superseded by the delta-hedge rebate** — `docs/superpowers/specs/2026-08-25-scratchpad-delta-hedge-rebate-design.md`, TODO #32: the holder hedges their own replica delta \(\hat\Delta^\sigma\) (Def 12) and the fee on the qualifying portion is refunded from streamia through the ledger of Defs 13–14; nothing is solved, \([\nu_{\mathrm{arb}}/\nu]\) is the residual output; the chain below is kept for the residual arb steps only): \(\pi^{\sigma} = \Delta Q_{\upsilon}(\sigma - \sigma_K)^{+}\) is \(\tau_{\mathrm{MEV}}\)-free, so all \(\tau_{\mathrm{MEV}}\) dependence of \(e^{\sigma}\) runs through the replica, along one explicit chain:

\[
	\begin{aligned}
		\tau_{\mathrm{MEV}} \;\to\; \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big](\tau_{\mathrm{MEV}}) \;\to\; \pi^{\mathrm{LVR}}(\mathcal{LC}_{\mathrm{leg}}) \;\to\; \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}}) = \pi^{\phi} - \pi^{\mathrm{LVR}} \;\to\; \hat{\pi^{\sigma}} = \sum_{\mathrm{leg}=0}^{3} \Big[ \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}}; p^{\star}_{1/2}) - \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}}; p_{1/2}) \Big] 
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

## REPLICATION_THEORY

Arc: the continuum \(\Pi^\sigma_{\mathrm{opt}}\) (`VariancePortfolio`) is not EVM-realizable; the 4-leg Panoptic replica \(\hat\pi^\sigma\) (`VolatilityReplica`) is. The intended route was to tune a Bunni liquidity density so that the realizable position matches the continuum. The results below (Lean, `lean4-spec`, Aristotle 18/18, axiom-clean) replace that tuning by closed forms; what remains numerical is stated in Corollary 3.

**Standing notation.** \(\lambda = 1.0001\); ticks \(i\), spacing \(\Delta_i\); \(p_{1/2}(i) = \lambda^{i/2}\), \(P = p_{1/2}^2\). Chunk \(\mathcal{LC} = (i^-, i^+, L)\), \(a = p_{1/2}(i^-)\), \(b = p_{1/2}(i^+)\), \(k_{1/2} = \sqrt{ab}\), \(r = b/a\). Span \([i_L, i_U]\), \(S = i_U - i_L\), rungs \(i_x = i_L + x\Delta_i\), \(x \in [0,\iota)\), \(\iota = S/\Delta_i\), mint tick \(i^\star\), \(\iota_P = (i^\star - i_L)/\Delta_i\). \(\mathrm{Id}_i = (i, i+\Delta_i, L_{\mathrm{unit}})\).

### Definitions

**Definition 1 (amounts).** \(\mathrm{amount}_0(\mathcal{LC}) = L\,\dfrac{b-a}{ab}\), \(\mathrm{amount}_1(\mathcal{LC}) = L\,(b-a)\). \(\;[\mathrm{amount}_0 \equiv \Delta Q_M^L,\ \mathrm{amount}_1 \equiv \Delta Q_X^L]\)

**Definition 2 (principal, anchor Def. 49).**
\[
\pi^{\Delta Q_X}(\mathcal{LC};p_{1/2}) =
\begin{cases}
L\,p_{1/2}^2\big(\tfrac1a - \tfrac1b\big) & p_{1/2} < a\\
L\big(2p_{1/2} - a - p_{1/2}^2/b\big) & a \le p_{1/2} < b\\
L\,(b-a) & p_{1/2} \ge b
\end{cases}
\]

**Definition 3 (range accrual note, unit CLMM payoff).** For \(r>1\), \(a = k_{1/2}/\sqrt r\), \(b = k_{1/2}\sqrt r\):
\[
\pi^{\mathrm{RAN}}(k_{1/2},r;p_{1/2}) =
\begin{cases}
0 & p_{1/2}<a \ \text{or}\ p_{1/2}\ge b\\
\dfrac{2p_{1/2}k_{1/2}\sqrt r - p_{1/2}^2 r - k_{1/2}^2}{r-1} & a\le p_{1/2}<k_{1/2}\\
\dfrac{2p_{1/2}k_{1/2}\sqrt r - p_{1/2}^2 - k_{1/2}^2 r}{r-1} & k_{1/2}\le p_{1/2}<b
\end{cases},
\qquad U(k_{1/2},r;p_{1/2}) = \min(P,K) + \pi^{\mathrm{RAN}}(k_{1/2},r;p_{1/2}).
\]

**Definition 4 (geometric profile, anchor \(\ell(\xi,\iota;\cdot)\)).** \(\ell(\xi,\iota;x) = \dfrac{\xi^x(1-\xi)}{1-\xi^\iota}\), \(\xi>0\), \(\xi\ne1\); \(\xi^\star = \lambda^{-\Delta_i/2}\).

**Definition 5 (two-kernel profile, anchor Def. 50).** \(\theta_{\mathrm{LDF}} = (\xi_P,\xi_C,\omega)\):
\(\ell_\theta(x) = \omega\,\ell(\xi_P,\iota_P;x)\,\mathbb 1_{x<\iota_P} + (1-\omega)\,\ell(\xi_C,\iota-\iota_P;x-\iota_P)\,\mathbb 1_{x\ge\iota_P}\).

**Definition 6 (hedged rung; Lean-only object, no anchor glyph).**
\(H_x(p_{1/2}) = \mathrm{amount}_1(\mathrm{Id}_{i_x})\) if \(i_x<i^\star\), \(=p_{1/2}^2\,\mathrm{amount}_0(\mathrm{Id}_{i_x})\) if \(i_x\ge i^\star\);
\(h_x(p_{1/2}) = H_x(p_{1/2}) - \pi^{\Delta Q_X}(\mathrm{Id}_{i_x};p_{1/2})\).

**Definition 7 (tiers).**
- T0 (**reference only**, not a position): \(\Pi^\sigma_{\mathrm{opt}}(P) = N_{\mathrm{id}}\big[(P-P^\star)/P^\star - \ln(P/P^\star)\big] + R\), \(\;\mathrm{logPortfolio}(P,P^\star) = (P-P^\star)/P^\star - \ln(P/P^\star)\) — single code definition `Payoffs.Log.logPortfolioQ96`; `VariancePortfolio` is \(N_{\mathrm{id}}\cdot\) it \(+R\) (TODO #29).
- T1: \(L(i_x) = \Delta Q_v^\star\,\ell(\xi^\star,\iota;x)\), \(\;\hat\pi^\sigma_{\mathrm{T1}}(p) = \sum_x \tfrac{L(i_x)}{L_{\mathrm{unit}}}\,h_x(p)\), \(\;\mathcal N_1 = \sum_x \tfrac{L(i_x)}{L_{\mathrm{unit}}}H_x(p^\star)\).
- T2: \(\hat\pi^\sigma(p) = \sum_{\mathrm{leg}=0}^{3}\big[H_{\mathrm{leg}}(p) - \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};p)\big]\), \(\mathcal{LC}_{\mathrm{leg}}\) from \(\mathrm{or}(\mathrm{leg})\cdot\texttt{positionSize}\) on the token1 basis (`asset = 1`).

**Definition 8 (binning \(\mathcal B\), objective).** \(c_x = (b_x-a_x)/Q96\), \(n_{\mathrm{leg}} = \sum_{x\in\mathrm{leg}} L(i_x)c_x\), \(\mathrm{or}(\mathrm{leg}) = \mathrm{round}(127\,n_{\mathrm{leg}}/n_{\max})\), \(\texttt{positionSize} = \lfloor n_{\max}/127\rfloor\).
\[
e^\sigma_W(\theta) = \frac{1}{\mathcal N_1}\Big(\frac{1}{|W|}\sum_{i\in W}\big[\hat\pi^\sigma_{\mathrm{T2}}(\mathcal B(\ell_\theta);p_{1/2}(i)) - \hat\pi^\sigma_{\mathrm{T1}}(\xi^\star;p_{1/2}(i))\big]^2\Big)^{1/2},\qquad W = [i_L - S,\ i_U + S].
\]

**Problem.** \(\min_{\theta_{\mathrm{LDF}},\,S}\ e^\sigma_W(\theta)\) subject to Panoptic constraints (4 legs, \(\mathrm{or}\in\{1..127\}\), 12-bit width, tick grid).

### Theorems (machine-proved)

**Theorem 1 (amounts invert liquidity).** For \(0<a<b\): \(\mathrm{amount}_0,\mathrm{amount}_1\) are two-sided inverses of `getLiquidityForAmount0/1`. \(\;\)[`LadderPrincipal.amounts_invert_liquidity`]

**Theorem 2 (principal structure).** For \(0<a<b\), \(L\ge0\): (i) in range, \(\pi^{\Delta Q_X}(\mathcal{LC};p_{1/2}) = \mathrm{amount}_1(L,a,p_{1/2}) + p_{1/2}^2\,\mathrm{amount}_0(L,p_{1/2},b)\); (ii) \(p_{1/2}\mapsto\pi^{\Delta Q_X}\) is continuous; (iii) \(P\mapsto\pi^{\Delta Q_X}(\mathcal{LC};\sqrt P)\) is concave on \(P\ge0\) (infimum of the tangent family \(T_t(P)=L(t-a+P/t-P/b)\), \(t\in[a,b]\)); not concave in \(p_{1/2}\). \(\;\)[`principal_inRange`, `principal_continuous`, `principal_concaveOn_price`]

**Theorem 3 (per-tick CLMM identity; anchor Thm. 49).** For all \(p_{1/2}>0\):
\[
\pi^{\Delta Q_X}(\mathcal{LC};p_{1/2}) = \mathrm{amount}_0(\mathcal{LC})\cdot U(k_{1/2},r;p_{1/2}),\qquad k_{1/2}=\sqrt{ab},\ r=b/a .
\]
Both RAN arms reduce to \(a(2p_{1/2}b - p_{1/2}^2 - ab)/(b-a)\). \(\;\)[`ClmmIdentity.principal_eq_amount0_mul_unit`; Haskell witness PR #53]

**Theorem 4 (RAN).** \(\pi^{\mathrm{RAN}}(k_{1/2},r;a)=\pi^{\mathrm{RAN}}(k_{1/2},r;b)=0\); \(\pi^{\mathrm{RAN}}\le0\) on \([a,b)\) for \(r>1\); \(\pi^{\mathrm{RAN}}(k_{1/2},r;k_{1/2}) = -k_{1/2}^2(\sqrt r-1)^2/(r-1)\). \(\;\)[`ran_endpoints`, `ran_nonpos`, `ran_at_strike`]

**Theorem 5 (gamma carrier; anchor Thm. 48).** On \(a^2<P<b^2\): \(\dfrac{\partial^2\pi^{\Delta Q_X}}{\partial P^2} = -\tfrac12\,L\,\Gamma_\varphi(P)\). \(\;\)[`principal_price_second_deriv`]

**Theorem 6 (profile).** For \(\xi>0\), \(\xi\ne1\), \(0<\iota_P<\iota\): (i) \(\sum_x\ell_\theta(x)=1\) for every \(\omega\); (ii) if \(\xi_P=\xi_C=\xi\) then \(\ell_\theta=\ell(\xi,\iota;\cdot)\) on all rungs \(\iff\) \(\omega=\omega^\star=\dfrac{1-\xi^{\iota_P}}{1-\xi^{\iota}}\). \(\;\)[`GeomMixture.mixWeight_sum`, `mix_eq_single_iff`]

**Theorem 7 (liquidity layer is geometric; \(\xi^\star\) is optimal).** Let \(w^\star_\iota(x)\) be the \(K^{-1/2}\) profile sampled at \(i_x\), normalized over \(\iota\) rungs. Then (i) \(w^\star_\iota = \ell(\xi^\star,\iota;\cdot)\); (ii) for \(\iota\ge2\), \(\xi^\star = \arg\min_{\xi}\sum_x(\ell(\xi,\iota;x)-w^\star_\iota(x))^2\), the minimum is \(0\) and is attained only at \(\xi^\star\). \(\;\)[`logLiqWeight_eq_geom`, `xiStar_argmin`; strike layer \(dK/K^2\) has ratio \(\lambda^{-\Delta_i}\): `GeomProfile.varswapWeight_normalized`]

**Theorem 8 (bin mean is the weighted-\(L^2\) minimizer).** For a bin \(B\ne\emptyset\), \(c_x>0\): \(\bar L_B = \sum_B c_xL_x/\sum_B c_x\) minimizes \(m\mapsto\sum_B c_x(L_x-m)^2\). \(\;\)[`wMean_minimizes`]

**Theorem 9 (hedged rung).** \(h_x\ge0\); \(h_x(p^\star)=0\) for every rung; \(h_x\) has four closed forms (below, two in-range arms, above). \(\;\)[`LadderLimit.hedgedRung_nonneg`, `hedgedRung_atStrike`, `hedgedRung_closed_forms`]

**Theorem 10 (T1 replicates T0, explicit constant).** Strike at the span midpoint. As \(\Delta_i\to0\) (\(\iota\to\infty\), \(S\) fixed):
\[
\frac{\hat\pi^\sigma_{\mathrm{T1}}(p)}{\mathcal N_1}\ \longrightarrow\ c(S)\cdot\mathrm{logPortfolio}(P,P^\star),\qquad
c(S) = \frac{1}{2\Big(\dfrac{\ln\lambda\, S}{4} + \dfrac{1-\lambda^{-S/2}}{2}\Big)}\quad(c(4000)=2.62294).
\]
Proof shape: rung edges geometric; primitive \(W(p,t)=\ln t + p^2/(2t^2)\); telescoping squeeze \(a_0\tfrac12\,\mathrm{logPortfolio}\le\sum\le r\cdot(\cdot)\); \(\mathcal N_1 = a_0\big[(r-1)n + (1-r^{-2n})\tfrac{r}{r+1}\big]\). \(\;\)[`ladder_tendsto_logPortfolio`, `ladder_tendsto_logPortfolio_explicit`]

### Propositions (verified, not yet machine-proved)

**Proposition 1 (rate).** The convergence in Theorem 10 is \(O(\Delta_i^2)\) in the across-\(p\) spread (probe: \(5\cdot10^{-3}\to5\cdot10^{-5}\) for \(\Delta_i\ 200\to20\)). Statement of the \(O(\Delta_i)\) bound pending on the Lean side.

**Proposition 2 (off-midpoint strike).** Theorem 10 with \(i^\star\) at an arbitrary rung (skew \(\ne\tfrac12\)) — pending.

**Proposition 3 (\(\chi\) from the gamma carrier — closed).** \(\int_{a^2}^{b^2} -\tfrac12 L\,\Gamma_\varphi(P)\,dP = \partial_P\pi(b^2)-\partial_P\pi(a^2) = -\,\mathrm{amount0}(\mathcal{LC})\) by Theorem 5 and the principal's price-delta \(\partial_P\pi^{\Delta Q_X} = \mathrm{amount0}(L,\bar p,b)\) (`Payoffs.ReplicaDelta.principalDelta`, the per-leg component of Definition 12). Convention \(\chi := \mathrm{amount0} > 0\) (`Payoffs.LvrRate.chi`). Checked by finite differences of the payoff; Lean twin `chi_eq_amount0` pending (peer C1–C2).

**Proposition 4 (LVR rate per correction segment — derived; issue #51).** On a segment \([lo,hi]\) of a chunk marked at the corrected price \(p_j\): \(\mathrm{LVR}_{\mathrm{net}} = \mathrm{amount}_{in}\,[\rho-\phi]\), \(\rho = p_j^2/(lo\,hi)-1\) (up) or \((lo\,hi)/p_j^2-1\) (down), both token sides; when the segment ends at \(p_j\), \(\rho = r_{1/2}-1\), the sqrt-price return of the correction. So \(\lambda_{X/M} = r_{1/2}-1-\phi_{X/M}\) per unit arb volume: zero at a gap of \(2\phi\) ticks, slope 1 beyond. The MODEL_CLOSURE §2 form \(\phi(2e^{u/2}-1)^{+} = (\sigma_{IV}-\phi)^{+}\) is this under the *identification* \(\sigma_{IV}\equiv r_{1/2}-1\) (a relabeling; the map from the transactional \(u\) is open). Clipped segments (\(p_j\) beyond the chunk) follow the general \(\rho\); a narrow leg can be net-negative on the tail of a wide correction. Spec `docs/superpowers/specs/2026-08-25-scratchpad-lambda-xm-lvr-rate-design.md`; regressions on continuous liquidity (6 seeds × 3 amps × 3 fees: crossing window, \(\ge0\) under the rational band \(2\phi\), slope 1); `panel-lvr-rate-vs-step.png`.

### Corollaries (what replaces tuning)

**Corollary 1.** \(\mathcal{B}(\ell_\theta)\) at the Carr–Madan point is a closed form: \(\theta^\star = (\xi^\star,\xi^\star,\omega^\star)\) by Theorems 6–7, and the per-leg liquidity realized by Panoptic is the \(c\)-weighted mean of the rungs, which is the \(L^2\)-optimal coarsening by Theorem 8. No \((\xi_P,\xi_C,\omega)\) search.

**Corollary 2.** T2 is a function of T1 (Definition 8 applied to Theorem 7's ladder), and T1 is a function of T0 with known constant (Theorem 10); \(\hat\pi^\sigma\ge0\), \(=0\) at \(p^\star\) (Theorem 9 + Theorem 2(iii)).

**Corollary 4 (equal notional per rung at \(\xi^\star\)).** \(L(i_x)\propto p_{1/2}(i_x)^{-1}\) and \(b_x-a_x = p_{1/2}(i_x)(\lambda^{\Delta_i/2}-1)\), so \(L(i_x)(b_x-a_x)\) is constant in \(x\): the token1 notional per rung is uniform. Hence \(n_{\mathrm{leg}}\propto\) number of rungs in the leg, and for equal-length legs \(\mathcal B\) returns \(\mathrm{or}=(127,127,127,127)\) — the Carr–Madan point is *equal notional per leg*, and \(e^\sigma_W\) at that point is pure binning loss (Theorem 8). Measured: \(e^\sigma_W(\mathcal B)=2.1\times10^{-4}\) vs \(0.142\) for \((1,2,3,4)\), \(S=4000\), \(\Delta_i=10\). Width sweep (\(\Delta_i=10\), \(W\) = 3× span, stride 50): \(e^\sigma_W(\mathcal B)\) = 1.8e-6 (\(S=400\)), 1.2e-5 (1000), 4.8e-5 (2000), 2.1e-4 (4000), 1.1e-3 (8000) — \(\approx S^2\), the within-leg curvature lost by the bin mean (Theorem 8). Quantization error 0 ppm (bound 3937 ppm at \(\mathrm{or}=127\)).

**Corollary 3 (residual numerical problem).** \(e^\sigma_W\) decomposes as truncation (in \(S\)) + tick discretization (Proposition 1) + binning/7-bit quantization (relative \(\le1/(2\,\mathrm{or}(\mathrm{leg}))\)). The optimizer reduces to a 1-D sweep in \(S\) (equivalently `VolRangeWidth`) with a quantization report; the remaining theory gap is norm C (reweighting by the pricing measure \(m\), #17–#18).

**Implementation status.** T0 with continuous \(\ln\) (`lnQ96`, PR #64), T2 (`LegChunk`, `VolatilityReplica`, PR #57; token1 basis PR #62) and **T1** (`Payoffs.LadderPosition`: `ladderChunks`, `hedgedRung`, `ladderT1`, `ladderN1`, `cOfS`; regressions of Theorems 7(i), 9, 10 and Proposition 1 — T1/\(\mathcal N_1\) matches \(c(4000)\cdot\)logPortfolio to \(2.8\times10^{-6}\) at \(\Delta_i=10\); `outputs/Payoffs/Replica/panel-t1-vs-t0.png`) exist; \(\mathcal B\) (`Panoptic.Binning`: `ladderFromVolOrder`, `binToLegs`, `mintPlanFromLadder`, `quantizationReport`) and \(e^\sigma_W\) (`VolatilityReplica.replicaError`, `windowTicks`) exist — the optimizer is now a `VolRangeWidth` sweep (`outputs/Payoffs/Replica/panel-t2-vs-t1.png`, sweep printed by the app). Lean modules: `GeomProfile`, `GeomMixture`, `LadderPrincipal` (`develop` 8fdd875), `ClmmIdentity`, `LadderLimit` (`feat/lean4-spec` 36a560b, PR #46).

## CHANNEL_STATICS

Comparative statics of the two legs of \(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\) on the \(\mathcal B\) plan (S=4000), from `Payoffs.PathAccrual` over a synthetic tagged path (TODO #30; the prover path replaces it in #34). Axes are EVM-representable: share in pips (uint24, \(10^6=1\)), step in ticks, accruals as raw `PayoffX96` token1 words. Per step inside a chunk: amounts moved by `getAmount0/1`, fee on the token paid in, LVR on arb steps \(=\) the concavity gap (Theorem 5). \(\mathrm{LVR}_{\mathrm{net}}=\mathrm{LVR}_{\mathrm{gross}}-\mathrm{fees}_{\mathrm{arb}}\) (after-fee convention); \(\pi^{\varphi}=\mathrm{fees}_{\mathrm{trans}}-\mathrm{LVR}_{\mathrm{net}}\).

**Fact 1 (share axis, `panel-accrual-vs-arbshare.png`).** At fixed step size, \(\mathrm{fees}_{\mathrm{trans}}\) is antitone and \(\mathrm{LVR}_{\mathrm{gross}}\) monotone in \([\nu_{\mathrm{arb}}/\nu]\), both linear; total fees are invariant to the tag. Below the fee band \(\mathrm{LVR}_{\mathrm{net}}<0\) for every share: arbs pay more fee than they extract, and the seller's \(\pi^{\varphi}\) falls in the share only through lost transactional fees.

**Fact 2 (vol axis, `panel-accrual-vs-vol.png`).** At share 500000 pips, \(\mathrm{LVR}_{\mathrm{net}}\) crosses zero where the step exceeds the fee band (≈40–50 ticks for \(\phi_X=5\,\)bp, \(\phi_M=30\,\)bp), and \(\pi^{\varphi}\) peaks there: too little vol → few fees, too much → LVR dominates. This is the band-crossing form of \(\lambda_{X/M}\) (MODEL_CLOSURE §2) seen directly, and the reason \(\inf_\tau\) has an interior solution: the tax moves \([\nu_{\mathrm{arb}}/\nu]\) (Fact 1) but the *sign* of the arb's extraction is set by vol vs fee (Fact 2).

## MODEL_CLOSURE

Exact functional forms for \(\pi^{\phi}(\pi^{\Delta Q}_{\mathrm{trans}}(r^{e}_{\mathrm{trans}}))\) and \(\pi^{\mathrm{LVR}}(\pi^{\Delta Q}_{\mathrm{arb}}(r^{e}_{\mathrm{arb}}))\). Both channels have the same shape — a token-side mixture weighted by \(r^{e}\) — which is what closes the model.

**1. Fee channel (exact, no new object).** With the legs \(\pi^{\Delta Q}_{\mathrm{pay}} = P_{1/2}(1-\phi_X)\), \(\pi^{\Delta Q}_{\mathrm{recv}} = I(r_{1/2})(1-\phi_M)\), the fee on each leg is gross minus net:

\[
	\begin{aligned}
		\pi^{\phi}\big(\pi^{\Delta Q}_{\mathrm{trans}}(r^{e}_{\mathrm{trans}})\big) \, &= \, (1-r^{e}_{\mathrm{trans}}) \, \frac{\phi_X}{1-\phi_X} \, \pi^{\Delta Q}_{\mathrm{pay}} \, + \, r^{e}_{\mathrm{trans}} \, \frac{\phi_M}{1-\phi_M} \, \pi^{\Delta Q}_{\mathrm{recv}} \\[4pt]
		\phi_X = \phi_M = \phi \;\Rightarrow\; \pi^{\phi} \, &= \, \frac{\phi}{1-\phi} \, \pi^{\Delta Q}_{\mathrm{trans}} \qquad \text{(independent of } r^{e}\text{)}; \qquad r^{\phi} = \phi \, \delta_{\mathrm{trans}}
	\end{aligned}
\]

**2. LVR channel (same shape; two new primitives).** Split the anchor's \(\lambda_{\mathrm{ARB}}\) by token side exactly as the fee is split:

\[
	\begin{aligned}
		\lambda_{\mathrm{ARB}}(u, \phi;\, \mathcal{LC}_{\mathrm{leg}}) \, &= \, (1-r^{e}_{\mathrm{arb}}) \, \lambda_X(u, \phi_X;\, \mathcal{LC}_{\mathrm{leg}}) \, + \, r^{e}_{\mathrm{arb}} \, \lambda_M(u, \phi_M;\, \mathcal{LC}_{\mathrm{leg}}) \\[4pt]
		r^{\mathrm{LVR}} \, &= \, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] \, \lambda_{\mathrm{ARB}}, \qquad \pi^{\mathrm{LVR}} = \mathcal{N}_\pi^{-1} \, r^{\mathrm{LVR}}
	\end{aligned}
\]

\(\lambda_X, \lambda_M\) (per-token LVR rates) are the only new primitives. Candidate, band-crossing in state units — zero until implied vol exceeds the fee (\(\sigma_{\mathrm{IV}}/\phi = 2e^{u/2} > 1\)), linear beyond, \(\chi\) the chunk's in-range exposure from the three-piece \(\pi^{\Delta Q_X}(\mathcal{LC}; p_{1/2})\):

\[
	\begin{aligned}
		\lambda_{X/M}(u, \phi_{X/M};\, \mathcal{LC}_{\mathrm{leg}}) \, &\overset{?}{=} \, \phi_{X/M} \, \big( 2e^{u/2} - 1 \big)^{+} \cdot \chi(\mathcal{LC}_{\mathrm{leg}})
	\end{aligned}
\]

> **Derived (Proposition 4, 2026-08-25):** \(\lambda_{X/M} = \rho-\phi_{X/M}\) per unit arb volume on each correction segment, \(\rho = r_{1/2}-1\) (sqrt-price return) when the segment ends at the corrected price; rational corrections need gaps \(>2\phi\) ticks. \(\chi = \mathrm{amount0}\) (Proposition 3) enters through \(\mathrm{amount}_{in}\). The form above holds under the identification \(\sigma_{IV}\equiv r_{1/2}-1\) (the anchor's \(2\phi e^{u/2}\) with the transactional \(u\) is NOT derived from it). \(\lambda_X,\lambda_M\) are no longer primitives. Convention unchanged: LVR is the arb's **after-fee** profit; \(\pi^{\phi}\) stays transactional-only. Under the rebate the correction is the holder's at \(\phi_{\mathrm{eff}}=0\).

**3. Closure.** Every symbol on the right is observed or defined above except \(\lambda_X, \lambda_M\); the tax enters only through the bracket:

\[
	\begin{aligned}
		r^{\varphi} \, &= \, \phi \, \delta_{\mathrm{trans}} \, - \, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] \Big[ (1-r^{e}_{\mathrm{arb}}) \, \lambda_X + r^{e}_{\mathrm{arb}} \, \lambda_M \Big], \qquad
		\pi^{\varphi} = \mathcal{N}_\pi^{-1} \, r^{\varphi} \\[4pt]
		\hat{\pi^{\sigma}} \, &= \, \sum_{\mathrm{leg}=0}^{3} \Big[ \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}) - \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};\, p_{1/2}) \Big]
	\end{aligned}
\]

Inputs: \(\phi_{X/M}\) (`Quote`), \(\delta_{\mathrm{trans}}\) (#7/#23), \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] (atomic), \(r^{e}_{\mathrm{arb}} = \Lambda(\gamma(u - u^{\star}))\) (#21), \(u\), \(\mathcal{LC}_{\mathrm{leg}}\) (#25).

