# Scratchpad — the arb-leg weight ∂ in the expected-return split (closes TODO #22 / #28)

**Date:** 2026-08-25  
**Status:** design note (docs); two-reviewer pass done (Reality Checker, Model QA) — all BLOCKER/MAJOR findings folded in.  
**Notation anchor:** `VOLATILITY_INSTRUMENTS.md`; README (RARB) split and § MODEL_CLOSURE §3; rebate note (Defs 12–14, Prop B); λ note (Prop 4)

## 1. The question

README (RARB): \(r^{e}_{\Delta Q} = r^{e}_{\Delta Q_{\mathrm{trans}}} + \partial\cdot r^{e}_{\Delta Q_{\mathrm{arb}}}(\sigma_{IV}-\sigma^{e})\), with \(\partial \equiv \partial r^{e}_{\Delta Q}/\partial r^{e}_{\Delta Q_{\mathrm{arb}}}\big|_{r^{e}_{\mathrm{trans}}}\) "a definition by role; its formula is the open item". TODO #22: what object is it, units, bounds, who sets it, relation to the measure. (The symbol \(\beta\) was retired for it by user ruling; it is not the CES \(\beta=\eta\) nor the AdaptiveStremia logistic centres \(\beta_j\).)

**Flag for #21 slice 2.** README uses \(r^{e}_{\Delta Q_{\mathrm{arb}}}\) in two roles: in (RARB) as the arb leg's expected *return*, and in MODEL_CLOSURE §2 / TODO #21 as the token-side *mixture weight* \(\Lambda(\gamma(u-u^\star))\in[0,1]\). This note takes the (RARB) reading — a rate per unit of arb volume, of which Prop 4's \(\lambda\) is the ex-post instance — and leaves the symbol clash to #21.

## 2. Answer

**Ex-post identity.** Per unit of total token1 volume over a chunk list, \(r_{\Delta Q} = r_{\mathrm{trans}} + [\nu_{\mathrm{arb}}/\nu]\cdot r_{\mathrm{arb}}\) holds with \([\nu_{\mathrm{arb}}/\nu]\) the **token1** share \(\sum_{\mathrm{arb}}\mathrm{amount}_{in}/\sum_{\mathrm{all}}\mathrm{amount}_{in}\) (`Payoffs.HolderPath.arbShareToken1`, via `stepVolume1`) and \(r_{\mathrm{arb}}\) per unit arb token1 volume (`Payoffs.LvrRate.lvrRateOn`); both terms then share the denominator \(\nu\). `arbShare` (tick volume) is the liquidity-free proxy and coincides only on continuous liquidity with small ticks. The README's "read, not computed" convention is kept for the identity; the simulator *computes* the reader.

**Definition 15 (arb weight).** Taking \(\mathbb{Q}\)-expectations of the identity at fixed \(r^{e}_{\mathrm{trans}}\),
\[
\partial \;:=\; \frac{\mathbb{E}^{\mathbb{Q}}\big[[\nu_{\mathrm{arb}}/\nu]\cdot r_{\mathrm{arb}}\big]}{\mathbb{E}^{\mathbb{Q}}[r_{\mathrm{arb}}]}
\;=\; \mathbb{E}^{\mathbb{Q}}\big[[\nu_{\mathrm{arb}}/\nu]\big] + \frac{\mathrm{Cov}^{\mathbb{Q}}\big([\nu_{\mathrm{arb}}/\nu],\, r_{\mathrm{arb}}\big)}{\mathbb{E}^{\mathbb{Q}}[r_{\mathrm{arb}}]} .
\]
This is exactly the derivative the README defines by role, under linearity of \(r_{\Delta Q}\) in \(r_{\mathrm{arb}}\) (true of the identity). The covariance is not zero — both the share and \(r_{\mathrm{arb}}\) are driven by external vol — so \(\partial = \mathbb{E}^{\mathbb{Q}}[\text{share}]\) is the **zero-covariance approximation**, stated as such. Units: a share in \([0,1]\), pips (`ArbSharePips`, bounded to \([0,10^6]\); no EVM twin yet).

**Who sets it: nobody.** The share is *produced* by the update rule (`composedPath`): per round, trans noise \(\pm\)transAmp moves the pool, the external price moves \(\pm\)extAmp, then the holder corrects if active and \(|e-p|>\)gas, else an arbitrageur corrects if \(|e-p|>\)band, else no one (branch order `HolderPath.hs`, holder first). So \([\nu_{\mathrm{arb}}/\nu]\) is a function of (band, gas, holder flag, external vol, trans-noise amplitude) and the pricing measure enters only through the external process. \(\partial\) is its \(\mathbb{Q}\)-expectation over paths — **not** the rule evaluated at \(\sigma^{e}\): the share is a band-crossing indicator, nonlinear in the path, so \(\mathbb{E}^{\mathbb{Q}}[\text{share}(\text{path})] \ne \text{share}(\text{path at }\mathbb{E}^{\mathbb{Q}}\sigma)\) (Jensen). "Evaluate at \(\sigma^{e}\)" is a further approximation to be checked when \(\sigma^{e}\) (TODO #21 slice 2) exists. The band is an input; its rational value is \(2\phi\) ticks (`rationalBandTicks`, Prop 4) — §5.5 and the panel use band 30 with no fee link.

Code objects: `arbShareToken1` (new, the share of the identity), `arbShare` (proxy). The expectation itself has no code object: `composedPath` is a deterministic LCG path with no measure; \(\partial\) stays notes-only until #17/#21 provide \(\mathbb{Q}\).

**Statics and limits** (holder inactive unless said; regressed in `test/Spec.hs` "Def 15 statics", 4 seeds, on the sampled grids band \(\{0,10,20,40\}\), ext \(\{1,2,4,8\}\)):
- share \(=0\) iff the holder is active with gas \(\le\) band (holder branch first); gas \(>\) band \(>0\) leaves a positive arb share — both regressed;
- the **number** of arb corrections is nonincreasing in the band; the **volume** share is *not* monotone in the band (wider band: rarer but larger corrections; Model QA sweep: 284 of 882 adjacent band pairs violate monotonicity; e.g. 240819 pips at band 20 vs 245063 at 40, seed 5);
- share nondecreasing in external vol on the sampled grid (token1 share on continuous liquidity, tick share); on a unit-step grid single decreases occur (49 of 672 pairs), so the claim is about the \(\mathbb{Q}\)-average, not pathwise;
- band \(\to0\): every round is corrected; the share tends to \(\mathbb{E}|e'-p'|/(\mathbb{E}|e'-p'|+\text{transAmp})\), \(<1\) whenever trans noise is nonzero (measured 501246…842478 pips for ext 1…16 at trans \(\pm3\)).

## 3. What this does to (RARB) and MODEL_CLOSURE §3

Keep the ex-post bracket and the token-side mixture as written in README § MODEL_CLOSURE §3; the expectation form is the joint one:
\[
r^{\varphi} = \phi\,\delta_{\mathrm{trans}} - \big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\big]\big[(1-r^{e}_{\mathrm{arb}})\lambda_X + r^{e}_{\mathrm{arb}}\lambda_M\big],\qquad
\mathbb{E}^{\mathbb{Q}}[r^{\varphi}] = \phi\,\delta_{\mathrm{trans}} - \mathbb{E}^{\mathbb{Q}}\Big[\big[\tfrac{\nu_{\mathrm{arb}}}{\nu}\big]\cdot\lambda_{\mathrm{mix}}\Big],
\]
with \(\lambda_{X/M} = \rho-\phi_{X/M}\) from Prop 4 and \(\phi\delta_{\mathrm{trans}}\) from `Payoffs.TransactionalReturn`, both per unit of total token1 volume. Inputs: \(\phi_{X/M}\), band, gas, holder flag, external vol, trans-noise amplitude. Outputs of the rule: the share, \(\rho\) per correction. Notes-only expectations: \(\mathbb{E}^{\mathbb{Q}}[\cdot]\) and \(\sigma^{e}\) (#21 slice 2). #6 (`ExpectedReturn` composition) is unblocked on the *definition* of the weight and still waits on \(\mathbb{Q}\).

## 4. Economic meaning

The weight of the arbitrage leg in a pool's expected return is neither a preference parameter nor a pool constant: it is how often, and how much, the pool's price is corrected by someone other than its own traders — and who that someone is. Under the rebate the buyer is the corrector whenever gas \(\le\) band, and the arb leg's weight is zero: the instrument has internalized its hedging. Without the rebate the weight is the band-crossing statistic of the external price against the fee, jointly with how much each crossing extracts — a covariance, not a product of averages.
