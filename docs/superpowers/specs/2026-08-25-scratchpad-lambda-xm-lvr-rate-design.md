# Scratchpad — λ_{X/M}: the per-token LVR rate, derived (closes the MODEL_CLOSURE §2 design claim)

**Date:** 2026-08-25  
**Status:** design note + ex-post check; issue #51 (TODO #26 → #36). Two-reviewer pass done (Reality Checker, Model QA); all BLOCKER/MAJOR findings resolved in this version.  
**Notation anchor:** `VOLATILITY_INSTRUMENTS.md`; README § REPLICATION_THEORY (Thm 5, Prop 3, Prop 4), § CHANNEL_STATICS, § MODEL_CLOSURE §2

## 1. The claim

README MODEL_CLOSURE §2 posited
\[
\lambda_{X/M}(u,\phi_{X/M};\mathcal{LC}_{\mathrm{leg}}) \overset{?}{=} \phi_{X/M}\,(2e^{u/2}-1)^{+}\,\chi(\mathcal{LC}_{\mathrm{leg}}),
\]
zero until \(\sigma_{IV}/\phi = 2e^{u/2} > 1\), linear beyond, \(\chi\) = in-range exposure. Two objects were open: \(\chi\), and the functional form. §2 closes \(\chi\) exactly; §3 derives the form as an identity of the accrual accounting and states precisely which symbol of the claim is a derivation and which is an identification.

## 2. χ is exact (Proposition 3)

Theorem 5: \(\partial^2_P \pi^{\Delta Q_X} = -\tfrac12 L\,\Gamma_\varphi(P)\) on \(a^2<P<b^2\). The principal's price-delta (the per-leg component of Def 12, `Payoffs.ReplicaDelta.principalDelta`) is \(\partial_P \pi^{\Delta Q_X}(\mathcal{LC};P) = \mathrm{amount0}(L,\bar p,b)\), \(\bar p=\operatorname{clamp}(p;a,b)\): the token0 the chunk holds at \(p\). By the fundamental theorem of calculus,
\[
\int_{a^2}^{b^2} -\tfrac12 L\,\Gamma_\varphi\,dP \;=\; \partial_P\pi(b^2) - \partial_P\pi(a^2) \;=\; -\,\mathrm{amount0}(\mathcal{LC}).
\]
**Convention.** \(\chi(\mathcal{LC}) := \mathrm{amount0}(\mathcal{LC}) > 0\) (raw token0), so the integral equals \(-\chi\): \(\chi\) is the total delta the chunk sheds across its range. `Payoffs.LvrRate.chi = chunkAmount0`.

Status: the identity `chi = principalDelta(a) − principalDelta(b)` is a consistency check of one formula against itself; the **independent** check is `∫∂²π dP ≈ −χ` with deltas taken by finite differences of the payoff (`deltaOfPayoff` on `CLMMPosition.fromChunk`), test "Prop 3 ∫∂²π dP". The proof is the pending Lean `chi_eq_amount0` from `principal_price_deriv` (`lean4-spec/scratch/peer-from-scratchpad-chi.md`, C1–C2).

## 3. The form is exact per correction segment (Proposition 4)

`Payoffs.PathAccrual.stepAccrual` accounts one price move \(p_i\to p_j\) on a chunk by its overlap segment \([lo,hi]\subseteq[a,b]\): amounts by `getAmount0/1`, fee on the token paid in, LVR = the concavity gap **marked at the corrected price \(p_j\)** (which may lie beyond \(hi\) when the move exits the chunk).

- up (\(p_j\ge hi\)): \(\mathrm{amount}_{in} = \mathrm{amount1} = L(hi-lo)\); \(\mathrm{LVR}_{\mathrm{gross}} = \mathrm{amount0}\cdot p_j^2 - \mathrm{amount1} = L(hi-lo)\big[p_j^2/(lo\,hi) - 1\big]\).
- down (\(p_j\le lo\)): \(\mathrm{amount}_{in} = \mathrm{amount0}\cdot p_j^2 = L(hi-lo)\,p_j^2/(lo\,hi)\); \(\mathrm{LVR}_{\mathrm{gross}} = \mathrm{amount1} - \mathrm{amount0}\,p_j^2 = L(hi-lo)\big[1 - p_j^2/(lo\,hi)\big]\).

**Proposition 4 (LVR rate per correction segment).** On both token sides,
\[
\mathrm{LVR}_{\mathrm{net}} \;=\; \mathrm{amount}_{in}\cdot\Big[\rho - \phi\Big],\qquad
\rho = \begin{cases} p_j^2/(lo\,hi) - 1 & \text{up}\\[2pt] (lo\,hi)/p_j^2 - 1 & \text{down}\end{cases}
\]
and **when the segment ends at the corrected price** (\(p_j = hi\) up, \(p_j = lo\) down — every correction on continuous liquidity, and every correction inside a chunk) \(\rho = r_{1/2}-1\), \(r_{1/2} = hi/lo\): the *sqrt-price return of the correction*. Hence per unit of \(\mathrm{amount}_{in}\) the rate is \(\lambda = r_{1/2}-1-\phi\): zero at \(r_{1/2}-1=\phi\) (a gap of \(2\phi\) ticks — the arb captures half the price gap), linear beyond with slope 1. Token side selects \(\phi_X\) (down) or \(\phi_M\) (up): the \(\lambda_X/\lambda_M\) split of MODEL_CLOSURE §2. Signed: `stepAccrual` clamps the gross at 0 but the net is signed; the claim's \((\cdot)^+\) is the rational-arb restriction (§4), not what the accounting returns.

**Corollary (marginal segments).** A chunk overlapping only the *tail* of a wide correction has \(\rho = p_j^2/(lo\,hi)-1 < \phi\) possible, so a 10-tick leg can lose on a correction that is profitable for the arb overall. A 4-leg position's path rate is therefore a volume-weighted mean of \(\rho-\phi\) over clipped segments — not the pure law — while a chunk covering the path realizes the law exactly.

**Identification (not a derivation).** The anchor writes \(\sigma_{IV} = 2\phi e^{u/2}\), so \(\phi(2e^{u/2}-1) = \sigma_{IV}-\phi\). Prop 4 is that expression *if one defines* \(\sigma_{IV} \equiv r_{1/2}-1\), the realized sqrt-price displacement per correction. This is a relabeling that makes the claim's shape exact; the map from the anchor's transactional \(u\) to the per-correction \(r_{1/2}\) is **open** (rebate note §5 already separates the two "u"s). \(\chi\) enters as claimed — through \(\mathrm{amount}_{in}\), i.e. the three-piece \(\pi^{\Delta Q_X}\) — but it is the segment amount (token1), not \(\chi\) itself; over a full down-range it is \(\chi\cdot p_j^2\) valued in token1.

Regressions (`test/Spec.hs`): step identity up and down, \(g=1..10\) ticks (rel \(10^{-5}\) or 2 wei); clipped-segment form for \(g\in\{1,5,20,60\}\) beyond the chunk; zero crossing at \(g=2\cdot\)band with \(|\mathrm{net}(2\,\mathrm{band})|\) an order below its neighbours. Oracle: these are regressions of the accounting against its own algebra; the independent statement is C3 `lvr_net_step` in the peer file.

## 4. Ex-post check on the composed path

`Payoffs.LvrRate.lvrRateOn`: holder inactive; \(\lambda(s,\phi,\text{band}) = \mathrm{LVR}_{\mathrm{net}}\big/\sum \mathrm{amount}_{in}\) over arb segments (both token1, `stepVolume1`), reported in **pips** so \(\lambda\) and \(\phi\) share an axis; \(s\) = external step per round. Corrections after a round have size \(s\pm\)transAmp, so with the naive band (\(\phi\) in price ticks) all corrections are below \(2\phi\) iff \(s \le 2\phi - 2\,\)transAmp and all above iff \(s\ge 2\phi+\)transAmp — the test windows are derived, not tuned.

Continuous liquidity (one chunk over the path; every correction ends at \(p_j\)), 6 seeds × transAmp \(\{1,2,4\}\) × \(\phi\in\{1000,2000,3000\}\) pips:
- naive band: \(\lambda\le0\) below the window, \(>0\) above;
- rational band \(2\phi\) ticks: \(\lambda\ge0\) at every \(s\);
- transAmp 1: \(\lambda(s) = (s/2-\text{band})\cdot100\) pips \(\pm60\) for all \(s\) above the window — slope 1 in sqrt-return, all seeds and fees (e.g. \(\phi=3000\): \(-998\) at \(s=40\), \(-598\) at 48, \(+4\) at 60).

4-leg position (`planBig`, legs 10 ticks wide): almost no correction lies inside a leg (Model QA probe: 0 of 295–600 fully inside; 27–37 overlapping), so the path rate is the Corollary's clipped mean. It is printed as a seed-5 regression, not asserted: \(\phi=1000\): \(-190, 47, 537, 1069, 1602, 2135\) pips at \(s = 10..60\) — crossing ≈ 19 ticks, slope ≈ 53 pips/tick vs 50; the excess is the \(p_j\)-marking of clipped segments. An earlier draft divided by arb *tick* volume and read the resulting concavity as "out-of-range dilution"; that denominator was the wrong unit and the explanation is withdrawn.

Panel `outputs/Payoffs/Accrual/panel-lvr-rate-vs-step.png`: left, 4-leg naive vs rational bands for \(\phi\in\{1000,2000\}\); right, continuous liquidity at \(\phi=1000\) (crossing at 20, rational \(\ge0\)). Axes: ticks × pips.

## 5. Consequences

- MODEL_CLOSURE §2's design claim is replaced by Prop 4: \(\lambda_{X/M} = (\rho-\phi_{X/M})\) per unit arb volume, \(\rho = r_{1/2}-1\) on unclipped segments. \(\lambda_X,\lambda_M\) are no longer primitives; §3's closure reads \(r^{\varphi} = \phi\delta_{\mathrm{trans}} - [\nu_{\mathrm{arb}}/\nu]\,\mathbb{E}_{\mathrm{arb}}[\rho-\phi]\) with the token-side mixture over up/down corrections.
- Rational arbitrage: corrections occur iff \(r_{1/2}-1>\phi\), i.e. gaps \(>2\phi\) ticks. `Payoffs.HolderPath.Regime.rgBandTicks` is a price-tick trigger; its rational value is `rationalBandTicks φ = 2·φ/100`. Fact 2's crossing at 40–50 ticks for \(\phi_M=30\) bp is consistent with \(2\phi = 60\) ticks under a naive-band path (the `syntheticPath` steps are not rational corrections); a computed reconciliation is not claimed.
- Under the rebate (holder active), corrections are Holder-tagged at \(\phi_{\mathrm{eff}}=0\): \(\lambda = \rho\), the whole gap to the holder (Prop B).
- For Aristotle (C3): \(\lambda\ge0\) iff \(\rho\ge\phi\); nondecreasing in \(r_{1/2}\), nonincreasing in \(\phi\) — algebraic. \(\partial\pi^{\phi}/\partial[\nu_{\mathrm{arb}}/\nu]=0\) is the after-fee *convention* (fees on arb steps are netted inside \(\lambda\)), not a consequence of Prop 4.

## 6. Economic meaning

An arbitrageur's after-fee profit on a correction is the sqrt-price move they capture minus the fee they pay, per unit traded; the LP loses exactly that, segment by segment. Because the arb's fill averages half the price gap, the fee band is \(2\phi\) in price ticks. A concentrated position sees only the segments of corrections that cross its range and can be net-negative on the tail of a wide move even when the arb is rational: concentration converts a pool-level law into a range-weighted one. Implied vol in the anchor's \(2\phi e^{u/2}\) is the same quantity read as a rate — once the transactional \(u\) is mapped to the per-correction displacement, which remains the open link.
