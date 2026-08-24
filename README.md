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
CLMM identity (TODO #24 / #35, `CLMMPosition`) — **proved** (closed form, 2026-08-23; Haskell witness `Payoffs.ChunkPrincipal` + `test/Spec.hs`), exact for every \(p_{1/2}\) below, inside and above the range:

\[
	\begin{aligned}
		\pi^{\Delta Q_X}\big(\mathrm{Id}_i[\mathcal{LC}];\, p_{1/2}\big) \, &= \, \mathrm{amount}_0\big(\mathrm{Id}_i[\mathcal{LC}]\big) \, \Big[ \pi^{c|p}\big(k_{1/2}(i, i+\Delta_i)\big) + \pi^{\mathrm{RAN}}\big(k_{1/2}(i, i+\Delta_i), \, r(i, i+\Delta_i)\big) \Big] \\[4pt]
		\mathrm{amount}_0\big(\mathrm{Id}_i[\mathcal{LC}]\big) \, &= \, 1e18 \, \Big( \frac{1}{p_{1/2}^{(\mathrm{bid})}} - \frac{1}{p_{1/2}^{(\mathrm{ask})}} \Big)
	\end{aligned}
\]

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

Objective (anchor \(e^{\sigma} = |\pi^{\sigma} - \hat{\pi^{\sigma}}|\)): \(\pi^{\sigma} = \Delta Q_{\upsilon}(\sigma - \sigma_K)^{+}\) is \(\tau_{\mathrm{MEV}}\)-free, so all \(\tau_{\mathrm{MEV}}\) dependence of \(e^{\sigma}\) runs through the replica, along one explicit chain:

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

## LADDER_REPLICATION

Spec: `docs/superpowers/specs/2026-08-24-scratchpad-ladder-replication-design.md` (v3, two reviewer passes). Goal: `VariancePortfolio` (T0, a strike **continuum**) is not EVM-realizable; the 4-leg replica \(\hat\pi^\sigma\) is. T0 enters the legs module **as the benchmark that selects the weights**, not as a second payoff construction — *Panoptic realizes, the LDF selects.*

**Tiers.** Rungs \(i_x = i_L + x\Delta_i\), \(x \in [0,\iota)\), \(\iota = (i_U - i_L)/\Delta_i\) from the `VolOrder`; hedged unit rung \(h_x(p_{1/2}) = H_x(p_{1/2}) - \pi^{\Delta Q_X}(\mathrm{Id}_{i_x};p_{1/2})\), \(H_x = \mathrm{amount}_1\) below \(i^\star\), \(p_{1/2}^2\,\mathrm{amount}_0\) above (same convention as the 4-leg replica).

| tier | object | realizable on | role |
|---|---|---|---|
| T0 | \(\Delta Q_v\,\Pi^\sigma_{\mathrm{opt}} = \Delta Q_v[N_{\mathrm{id}}(F - \mathrm{Log}) + R]\), `VariancePortfolio` with the continuous log `lnQ96` (Solady `lnWad` port; the tick-quantized log left a sawtooth of amplitude \(\tfrac12\ln\lambda\cdot Q96\), `outputs/Payoffs/Replica/panel-log-tick-vs-continuous.png`) | nowhere | reference / diagnostic |
| T1 | \(\hat\pi^\sigma_{\mathrm{T1}}(p) = \sum_x \tfrac{L(i_x)}{L_{\mathrm{unit}}}\,h_x(p)\), \(L(i_x) = \Delta Q_v^\star\,\ell(\xi^\star,\iota;x)\) | Bunni geometric LDF, per tick | **benchmark, fixed at \(\xi^\star\)** (LEAN_RESULTS A2) |
| T2 | `fourLegReplica` on \(\mathcal{LC}_{\mathrm{leg}}\) with \(\mathrm{or} = \mathcal{B}(\ell_\theta)\) | Panoptic | **realization, moves with \(\theta\)** |

**Knobs.** \(\theta_{\mathrm{LDF}} = (\xi_P, \xi_C, \omega)\) — the two-kernel profile (anchor Definition 50), put kernel on \([0,\iota_P)\), call kernel on \([\iota_P,\iota)\), \(\iota_P = (i^\star - i_L)/\Delta_i\) derived. Carr–Madan is the point \(\xi_P = \xi_C = \xi^\star\), \(\omega = \omega^\star\) (LEAN_RESULTS A4).

**Binning \(\mathcal{B}\)** (on token1 notional, one basis for all legs): \(n_{\mathrm{leg}} = \sum_{x \in \mathrm{leg}} L(i_x)\,c_x\), \(c_x = (b_x - a_x)/Q96\); \(\mathrm{or}(\mathrm{leg}) = \mathrm{round}(127\,n_{\mathrm{leg}}/n_{\max})\), \(\texttt{positionSize} = \lfloor n_{\max}/127 \rfloor\); reject if \(\mathrm{or} < \mathrm{or}_{\min}\). The realized leg liquidity is the \(c\)-weighted **mean** of the rungs (LEAN_RESULTS A3 — this is the binning loss, and it is the L² optimum). T2 is a function of T1.

**Objective (norm B; norm C = reweight by \(m(\cdot)\), later).** \(W\) = every tick on 3× the span:

\[
e^{\sigma}_W(\theta) = \frac{1}{\mathcal{N}_1}\Big(\frac{1}{|W|}\sum_{i \in W}\big[\hat\pi^\sigma_{\mathrm{T2}}(\mathcal{B}(\ell_\theta);p_{1/2}(i)) - \hat\pi^\sigma_{\mathrm{T1}}(\xi^\star;p_{1/2}(i))\big]^2\Big)^{1/2},
\qquad \mathcal{N}_1 = \sum_x \tfrac{L(i_x)}{L_{\mathrm{unit}}} H_x(p^\star)
\]

Error decomposition: truncation (span; `VolRangeWidth`) + tick discretization (T0 → T1; `lnQ96`, \(\Delta_i\)) + binning/quantization (T1 → T2; 7-bit \(\mathrm{or}\)). With A2/A3/A4 proved there is **no \((\xi,\omega)\) search** left: \(\mathcal{B}\) is computed; what remains is the width sweep and the quantization report.

**Status.** Items 0 (asset bit, `integerSqrt` strike, `mulDiv`; PR #62) and 1 (`lnQ96`; PR #64) done; Item 2 (T1 in Haskell, `ErrorX96`, differential tests) and Item 3 (\(\mathcal{B}\), `replicaError`, width sweep) open — TODO #28.

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

> DESIGN CLAIM — not derived; needs the #24 CLMM identity and an Aristotle / empirical check. Convention: LVR is the arb's **after-fee** profit, so the fee paid by arbs is netted inside \(\lambda_{X/M}\) and \(\pi^{\phi}\) stays transactional-only.

**3. Closure.** Every symbol on the right is observed or defined above except \(\lambda_X, \lambda_M\); the tax enters only through the bracket:

\[
	\begin{aligned}
		r^{\varphi} \, &= \, \phi \, \delta_{\mathrm{trans}} \, - \, \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] \Big[ (1-r^{e}_{\mathrm{arb}}) \, \lambda_X + r^{e}_{\mathrm{arb}} \, \lambda_M \Big], \qquad
		\pi^{\varphi} = \mathcal{N}_\pi^{-1} \, r^{\varphi} \\[4pt]
		\hat{\pi^{\sigma}} \, &= \, \sum_{\mathrm{leg}=0}^{3} \Big[ \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};\, p^{\star}_{1/2}) - \pi^{\Delta Q_X}(\mathcal{LC}_{\mathrm{leg}};\, p_{1/2}) \Big]
	\end{aligned}
\]

Inputs: \(\phi_{X/M}\) (`Quote`), \(\delta_{\mathrm{trans}}\) (#7/#23), \Big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\Big] (atomic), \(r^{e}_{\mathrm{arb}} = \Lambda(\gamma(u - u^{\star}))\) (#21), \(u\), \(\mathcal{LC}_{\mathrm{leg}}\) (#25).

## LEAN_RESULTS

Machine-proved results from `~/cfmms-playground/cfmm-wt/lean4-spec` (branch `develop` 8fdd875, Aristotle project 32b8b48e, 9/9 proved, no `sorry`, axiom-clean; second bundle 63e575db in flight), restated in this README's notation. Objects: rung index \(x \in [0,\iota)\), \(i_x = i_L + x\Delta_i\); chunk \(\mathcal{LC} = (i^-, i^+, L)\) with \(a = p^{(\mathrm{bid})}_{1/2}\), \(b = p^{(\mathrm{ask})}_{1/2}\); profile \(\ell(\xi,\iota;x)\); \(\xi^\star = \lambda^{-\Delta_i/2}\); bare principal \(\pi^{\Delta Q_X}(\mathcal{LC};\, p_{1/2})\).

**Ladder / LDF layer** (`GeomMixture.lean`, anchor Definition 50, Theorems 46–47)

| # | statement (our notation) | Lean name | what it buys |
|---|---|---|---|
| M0 | Two-kernel profile \(\ell_{\theta}(x) = \omega\,\ell(\xi_P,\iota_P;x)\,\mathbb{1}_{x<\iota_P} + (1-\omega)\,\ell(\xi_C,\iota_C;x-\iota_P)\,\mathbb{1}_{x\ge\iota_P}\), \(\theta_{\mathrm{LDF}} = (\xi_P,\xi_C,\omega)\), \(\iota_P = (i^\star - i_L)/\Delta_i\) derived: \(\sum_x \ell_\theta(x) = 1\) for every \(\omega\) | `mixWeight`, `mixWeight_sum` | \(\theta_{\mathrm{LDF}}\) is a well-formed density for any knob setting — no renormalization step in the tuner |
| A4 | With a common base \(\xi_P = \xi_C = \xi\): \(\ell_\theta = \ell(\xi,\iota;\cdot)\) on all rungs **iff** \(\omega = \omega^\star = \dfrac{1-\xi^{\iota_P}}{1-\xi^{\iota}}\) | `mix_eq_single_iff` | \(\omega\) is **not a free knob** at the Carr–Madan point; any other \(\omega\) puts a jump at \(i^\star\) |
| A3 | For bin \(B\) with weights \(c_x > 0\): the \(c\)-weighted mean \(\bar L_B = \sum_B c_x L_x / \sum_B c_x\) minimizes \(\sum_B c_x (L_x - m)^2\) over all \(m\) | `wMean`, `wMean_minimizes` | the 4-leg binning \(\mathcal{B}\) is a **closed form**: \(\mathrm{or}(\mathrm{leg}) \propto\) bin notional; there is nothing to search over per leg |
| A2a | The sampled log-contract liquidity profile \(K^{-1/2}\big|_{i_x}\), normalized over \(\iota\) rungs, **is** \(\ell(\xi^\star,\iota;x)\) | `logLiqWeight_eq_geom` | the variance-swap ladder is exactly geometric at \(\xi^\star\) — T1 is the right object |
| A2b | \(\xi^\star\) minimizes \(\sum_x \big(\ell(\xi,\iota;x) - K^{-1/2}\text{-profile}\big)^2\) over \(\xi > 0, \xi \ne 1\); the minimum is 0 and is attained **only** at \(\xi^\star\) (\(\iota \ge 2\)) | `xiStar`, `l2dist`, `xiStar_argmin` | the \(\xi\) sweep of the spec's test (c) is a theorem; liquidity layer \(\lambda^{-\Delta_i/2}\), **not** the strike layer \(\lambda^{-\Delta_i}\) (`varswapWeight_normalized`) |

**Principal layer** (`LadderPrincipal.lean`, anchor Definition 49, Theorem 45, Proposition 17)

| # | statement (our notation) | Lean name | what it buys |
|---|---|---|---|
| I0 | \(\mathrm{amount}_0 = L\,(b-a)/(ab)\), \(\mathrm{amount}_1 = L\,(b-a)\) are the inverses of `getLiquidityForAmount0/1` in both directions (\(0<a<b\)) | `amount0`, `amount1`, `amounts_invert_liquidity` | \(\mathrm{or}(\mathrm{leg}) \to L_{\mathrm{leg}}\) (`legLiquidity`) and back is exact; \(\mathrm{amount}_0 \equiv \Delta Q_M^L\), \(\mathrm{amount}_1 \equiv \Delta Q_X^L\) |
| P2 | In range (\(a \le p_{1/2} < b\)): \(\pi^{\Delta Q_X}(\mathcal{LC};p_{1/2}) = \mathrm{amount}_1(L,a,p_{1/2}) + p_{1/2}^2\,\mathrm{amount}_0(L,p_{1/2},b)\) | `principal_inRange` | the Uniswap split at the current price; Haskell regression in `test/Spec.hs` |
| P1 | \(p_{1/2} \mapsto \pi^{\Delta Q_X}(\mathcal{LC};p_{1/2})\) is continuous | `principal_continuous` | no jumps at the range edges — the replica \(\hat\pi^\sigma\) is continuous |
| P3 | \(P \mapsto \pi^{\Delta Q_X}(\mathcal{LC};\sqrt P)\) is concave on \(P \ge 0\) (as the infimum of the tangent family \(T_t(P) = L(t - a + P/t - P/b)\), \(t \in [a,b]\)); **not** concave in \(p_{1/2}\) (refuted: below range it is \(\propto p_{1/2}^2\)) | `principal_concaveOn_price` | each long leg \(H - \pi^{\Delta Q_X}\) is convex in price ⇒ \(\hat\pi^\sigma \ge 0\), \(=0\) at \(p^\star\) |

**In flight** (bundle 63e575db, `ClmmIdentity.lean`): A6a the per-tick CLMM identity \(\pi^{\Delta Q_X}(\mathrm{Id}_i;p_{1/2}) = \mathrm{amount}_0(\mathrm{Id}_i)\,[\min(P,K) + \pi^{\mathrm{RAN}}(k_{1/2},r)]\) with \(k_{1/2} = \sqrt{ab}\), \(r = b/a\) (hand proof + Haskell witness, PR #53; numerics \(1.3\times10^{-13}\)); RAN lemmas R1–R3 (endpoints, \(\le 0\), value at strike); **Proposition 17** \(\partial^2 \pi^{\Delta Q_X}/\partial P^2 = -\tfrac12 L\,\Gamma_\varphi(P)\) in range — the principal **is** the gamma carrier, which is the object the \(\lambda_{X/M}\) LVR claim (#51) needs for \(\chi(\mathcal{LC})\). **Awaiting a ruling:** A1 (the hedged ladder \(\to c\cdot\)log contract as \(\Delta_i \to 0\), numerically true with \(c \approx 2.62\) on the probe span and \(O(\Delta_i^2)\) spread) needs a Lean `hedgedRung` object — (a) dedicated module or (b) scratch-only.

**Consequence.** Phase 2 of the ladder spec has no \((\xi,\omega)\) search: \(\mathcal{B}\) is the bin mean (A3) of the profile at \(\xi^\star\) (A2) with \(\omega^\star\) (A4). What remains numerical is the 7-bit quantization of \(\mathrm{or}(\mathrm{leg})\), the width/truncation trade-off, and the X96 implementation error.

