# Scratchpad — T1/T2 ladder replication of `VariancePortfolio` (Panoptic × LDF hybrid)

**Date:** 2026-08-24 (v3 — two-reviewer pass ×2: Reality Checker + Solidity Smart Contract Engineer; residuals listed in §10)  
**Status:** design  
**TODO:** #28 (TODO numbering; not GitHub issue #28) — depends on #25 (`LegChunk`, `fourLegReplica`, PR #57), #27 (`CLMMPosition.fromChunk`, PR #55), #24/#35 (per-tick identity, PR #53)  
**Notation anchor:** `~/cfmms-playground/cfmm-wt/lean4-spec/notes/VOLATILITY_INSTRUMENTS.md` (lines 192–235, 404–443, 1329–1334). New symbols relative to the anchor: \(\mathcal{B}\), \(W\), \(e^\sigma_W\), `ErrorX96`, \((\xi_P,\xi_C,\omega)\) — the latter is the concrete instance of the anchor's declared-but-undefined \(\theta_{\mathrm{LDF}}\).

## 1. Goal

`VariancePortfolio` (Hop A/B, \(\Pi^{\sigma}_{\mathrm{opt}} = N_{\mathrm{id}}[(P-P^\star)/P^\star - \ln(P/P^\star)] + R\)) is a strike **continuum** — not EVM-realizable as such. The 4-leg Panoptic replica \(\hat\pi^\sigma\) (`Payoffs.VolatilityReplica.fourLegReplica`) is realizable. This spec embeds the former into the latter **as the benchmark that selects the replica's weights**, not as a second construction of the payoff: the knobs are liquidity-density (LDF) shape parameters, the Panoptic legs are their 4-bin realization, and the distance between them is minimized. **Panoptic realizes, the LDF selects.**

## 2. Objects (anchor notation)

**Rung indexing.** A ladder over span \([i_L, i_U]\) with tick spacing \(\Delta_i\) has \(\iota = (i_U - i_L)/\Delta_i\) rungs at \(i_x = i_L + x\Delta_i\), \(x \in [0,\iota)\). The anchor's profile, in rung index:

\[
\ell(\xi, \iota; x) = \frac{\xi^{x}}{(1-\xi^{\iota})/(1-\xi)}, \qquad \sum_x \ell = 1, \qquad \xi^\star = \lambda^{-\Delta_i/2}
\]

(code: `LiquidityGrid.ell xi iota x`, `xiStar spacing`). The Lean lemmas `logContractLiquidity_geometric` / `strikeWeight_bridge` prove the **weight identity** (the liquidity profile \(\propto K^{-1/2}\) is geometric with ratio \(\xi^\star\)); they do **not** prove payoff replication — that is what Phase 1 tests. \(\iota\), \(\iota_P = (i^\star - i_L)/\Delta_i\), \(\iota_C = (i_U - i^\star)/\Delta_i\) are **derived from the `VolOrder`**, never free (all three ticks are `roundTick`-aligned).

**Hedged rung payoff.** Every tier is written in the **same hedged (long) form** that `fourLegReplica` already uses — mint value minus current principal, both in token1 at the current price:

\[
h_x(p_{1/2}) = H_x(p_{1/2}) - \pi^{\varphi}\big(\mathrm{Id}_{i_x}[\mathcal{LC}];\, p_{1/2}\big), \qquad
H_x = \begin{cases} \mathrm{amount}_1(\mathrm{Id}_{i_x}) & i_x < i^\star \ (\text{token1 received}) \\ p_{1/2}^{2}\,\mathrm{amount}_0(\mathrm{Id}_{i_x})/Q96 & i_x \ge i^\star \ (\text{token0 received}) \end{cases}
\]

\(h_x \ge 0\), \(=0\) at \(p^\star\), convex. (The bare principal \(\pi^\varphi\) is concave and non-zero at \(p^\star\); it is never compared to T0 directly.)

| tier | definition | realizable on | role |
|---|---|---|---|
| **T0** | \(\Delta Q_v\,\Pi^{\sigma}_{\mathrm{opt}}\) — `VariancePortfolio` (continuous log, §4) | nowhere | reference / diagnostic |
| **T1** | \(\hat\pi^{\sigma}_{\mathrm{T1}}(p) = \sum_x \mathrm{mulDiv}\big(L(i_x),\, h_x(p),\, L_{\mathrm{unit}}\big)\), \(L(i_x) = \mathrm{mulDiv}(\Delta Q_v^\star, \ell(\xi^\star,\iota;x), Q96)\), \(L_{\mathrm{unit}} = 10^{18}\) = the liquidity of \(\mathrm{Id}_{i_x}\) (so \(h_x\) is the unit-chunk hedged payoff and \(L/L_{\mathrm{unit}}\) rescales it — no double counting) | Bunni geometric LDF, per tick | **benchmark (fixed at \(\xi^\star\))** |
| **T2** | `fourLegReplica` on \(\mathcal{LC}_{\mathrm{leg}} = \) `legChunks` of the plan with \(\mathrm{or} = \mathcal{B}(\ell_\theta)\) | Panoptic | **realization (moves with \(\theta\))** |

**Scale bridge T1 ↔ T0 (Phase 1).** T1 is in token1; T0 is \(N_{\mathrm{id}}\)-scaled return \(\times Q96\times\Delta Q_v\). Both are normalized to returns before comparison: \(\tilde{\mathrm{T1}}(p) = \mathrm{mulDiv}(\hat\pi^\sigma_{\mathrm{T1}}(p), Q96, \mathcal{N}_1)\) with \(\mathcal{N}_1 = \sum_x L(i_x) H_x(p^\star)/L_{\mathrm{unit}}\) (token1 notional at mint), and \(\tilde{\mathrm{T0}}(p) = \mathrm{mulDiv}(\Pi^\sigma_{\mathrm{opt}}(p) - R, Q96, N_{\mathrm{id}}Q96)\) (bare \(F - \mathrm{Log}\)). Replication is then a **shape statement**: the ratio \(\tilde{\mathrm{T1}}/\tilde{\mathrm{T0}}\) is constant within tolerance over \(W\) **excluding an exclusion band** \(|i - i^\star| < k\Delta_i\) (default \(k = 2\)) where both vanish quadratically and integer floors dominate; the constant \(c\) is reported, not assumed. One worked numeric example at fixture values (two ticks, both paths, same `PayoffX96` word after scaling) is a Phase 1 deliverable.

**Knobs.** \(\theta_{\mathrm{LDF}} = (\xi_P, \xi_C, \omega)\): two geometric kernels, put kernel on rungs \([0,\iota_P)\), call kernel on \([\iota_P, \iota)\), each normalized on its own sub-span (Bunni `LibDoubleGeometricDistribution` semantics: contiguous, separately normalized, weighted sum), mixed with weight \(\omega\) on the put side. This is the concrete \(\theta_{\mathrm{LDF}}\) of the anchor's FUTURE MILESTONE. Bunni indexing is reversed: `LibDoubleGeometricDistribution` kernel **1** (`length1, alpha1, weight1`) is the left block from `minTick` = our put kernel; kernel **0** is the right block = our call kernel; \(\omega^\star = w_1/(w_0+w_1)\). The Carr–Madan point is \(\xi_P = \xi_C = \xi^\star\) **and** \(\omega = \omega^\star = \dfrac{1 - \xi^{\star\,\iota_P}}{1 - \xi^{\star\,\iota}}\) — at that point \(\omega\) is pinned (any other \(\omega\) puts a jump at \(i^\star\)). Free dimensions at the reference point: 2 (\(\xi_P, \xi_C\); \(\omega\) rides), matching the anchor's ladder deficit \(\iota - 2\) at \(\iota = 4\).

**Binning map \(\mathcal{B}\) — on notional, one basis for all legs.** Panoptic reads \(\mathrm{or}(\mathrm{leg})\cdot\texttt{positionSize}\) as a **token amount** in the numeraire selected by the leg's `asset` bit (`PanopticMath.getLiquidityChunk`: `asset == 0` → `getLiquidityForAmount0`, `asset == 1` → `getLiquidityForAmount1`; `asset` is independent of `tokenType` — it is "the basis of the position", not put/call). One `positionSize` is shared by all four legs, so the four notionals **must be commensurable**: this spec sets **`asset = 1` (token1 basis) on every leg**, puts and calls alike. Then, with the per-rung token1 conversion \(c_x = (b_x - a_x)/Q96\) (`getAmount1ForLiquidity` on the rung, telescoping over a leg):

\[
n_{\mathrm{leg}} = \sum_{x \in \mathrm{leg}} L(i_x)\, c_x, \qquad a_x, b_x = \texttt{sqrtPriceX96}(i_x), \texttt{sqrtPriceX96}(i_x + \Delta_i)
\]

\[
\mathrm{or}(\mathrm{leg}) = \mathrm{round}\big(127\, n_{\mathrm{leg}} / n_{\max}\big), \qquad \texttt{positionSize} = \lfloor n_{\max}/127 \rfloor \ (\text{token1, uint128: require } n_{\max} < 2^{135})
\]

so \(\mathrm{or}(\mathrm{leg})\cdot\texttt{positionSize} = n_{\mathrm{leg}}\) up to 7-bit quantization — relative error \(\le 1/(2\,\mathrm{or}(\mathrm{leg}))\) for non-max legs, \(< 127\) wei for the max leg (floor). The on-chain leg liquidity is then \(L_{\mathrm{leg}} = n_{\mathrm{leg}}/c_{\mathrm{leg}} = \sum_x L(i_x)c_x / \sum_x c_x\) — the **\(c\)-weighted mean** of the rung liquidities, not their sum; that mean is the binning loss. **Reject** \(\theta\) if any \(\mathrm{or}(\mathrm{leg}) < \mathrm{or}_{\min}\) (default 8) — no clamp, no zero (Panoptic `validate` reverts on 0). Leg intervals from `legIntervals`. **T2 is a function of \(\theta\) through \(\mathcal{B}\); the benchmark T1 is not.** (Per-leg `asset` was rejected: with token0 on the call side, \(n_{\max}\) mixes units and the ratio \(\approx p^\star\cdot 10^{d_1-d_0}\) leaves \([1/127,127]\) on every real pool.)

Note the token *received* at mint is still decided by `tokenType` (puts token1, calls token0), so \(H_x\) above is unchanged; `asset` only fixes the sizing basis.

**Window.** \(W\) = **every tick** on \([i_L - (i_U - i_L),\ i_U + (i_U - i_L)]\) (3× the `VolOrder` span, in ticks; no \(\sigma_K\), no \(t^\star\) — neither is a tick quantity in code). Truncation error is what \(W \supsetneq [i_L, i_U]\) exposes; it is moved by `VolRangeWidth`.

**Objective (norm B).**

\[
e^{\sigma}_W(\theta) = \frac{1}{\mathcal{N}_1}\Big( \frac{1}{|W|} \sum_{i \in W} \big[\hat\pi^{\sigma}_{\mathrm{T2}}(\mathcal{B}(\ell_\theta); p_{1/2}(i)) - \hat\pi^{\sigma}_{\mathrm{T1}}(\xi^\star; p_{1/2}(i))\big]^2 \Big)^{1/2}
\]

computed as: residual \(d_i\) (token1) → \(\tilde d_i = \mathrm{mulDiv}(d_i, Q96, \mathcal{N}_1)\) (**normalize by the token1 mint notional before squaring** — dimensionless, \(O(1)\) on \(W\)) → sum → `integerSqrt` → Q96. Off-chain (Haskell `Integer`); no on-chain bit bound is claimed. Subscript \(W\) distinguishes it from the README's \(e^\sigma(\tau_{\mathrm{MEV}})\). T0 reported alongside as diagnostic. **Norm C (later)** = weight the sum by \(m(\cdot)\) (#17–#18).

Error decomposition: **truncation** (span; `VolRangeWidth`), **tick discretization** (T0 → T1; the continuous-log gap and tick spacing), **binning + quantization** (T1 → T2; \(\theta\) through \(\mathcal{B}\), 7-bit \(\mathrm{or}\)).

## 3. Fixed-point types and arithmetic discipline

All model quantities are `Integer` newtypes at Q96/WAD; `Double` only at plot boundaries. **Known existing leaks on the T1/T2 path (to be closed or budgeted, not denied):** `CLMMPosition.strikeAndRatio` (`sqrt :: Double`, `OptionRatio Double`), `chunkFromStrike` (`sqrt r`), `sqrtPriceX96` (`Double` power), `Log.nakedLogQ96` (`log tickBase`). Item 0 below closes the first; the rest are budgeted in every tolerance until ported.

| object | type | status |
|---|---|---|
| \(\xi\), \(\xi^\star\) | `XiX96`, `xiStar :: TickSpacing -> XiX96` | exists |
| Bunni twin of \(\xi\) | `xiToAlpha8 :: XiX96 -> Integer` (`alpha` at `ALPHA_BASE = 1e8`, bounds \([10^3, 12\cdot10^8]\), \(\ne 10^8\)); per-rung error \(\le 5\cdot10^{-9}\) relative, linear in \(\iota\) | new |
| \(\iota,\iota_P,\iota_C\) | `LadderResolution`, derived from `VolOrder` | exists / derived |
| \(\ell(\xi,\iota;x)\) | `ell :: XiX96 -> LadderResolution -> Int -> LiquidityDensityX96` (matches `LibGeometricDistribution.liquidityDensityX96` term-for-term) | exists |
| \(\omega\) | `BunniWeights = (w0, w1) :: (uint32, uint32)` — `w1` is the **put** (left) kernel; `mixEll` = `weightedSum` (each kernel already floors in `liquidityDensityX96`, then one more floor — three floors, budgeted) | new |
| mixture | `mixEll :: BunniWeights -> (XiX96, LadderResolution) -> (XiX96, LadderResolution) -> Int -> LiquidityDensityX96` (\(G = 2\) only — Bunni implements no more) | new |
| \(\Delta Q_v^\star\) | `TargetVega` (uint128) | exists |
| rung chunk | `LiquidityChunk`; \(L(i_x) = \mathrm{mulDiv}(\Delta Q_v^\star, \ell, Q96)\); uint128 guard | exists |
| `mulDiv` | `mulDiv :: Integer -> Integer -> Integer -> Integer` (single floor; twin is the **full-precision 512-bit** `FullMath.mulDiv`, never naive `a*b/c`); **bare `a*b*c \`div\` d` forbidden** in new code | new |
| staged forms | `chunkAmount0 = mulDiv(L·2^96, b−a, b) / a`; (with `asset = 1` everywhere `legLiquidity = mulDiv(amt, Q96, b−a)` on all legs; the token0 form `mulDiv(amt, mulDiv(a,b,Q96), b−a)` is kept for `asset = 0`); `legMintValue` call branch two `mulDiv`s; `chunkAmount0/1` outputs uint128-checked (Panoptic `toUint128`) | change |
| payoff | `PayoffX96` — **signed** (`h − principal`), int256 twin | exists |
| error | `ErrorX96` (Q96); off-chain surface | new |
| window | `[Tick]` | — |
| \(\mathrm{or}(\mathrm{leg})\) | `Integer` 1..127; `positionSize` uint128 | exists |
| LDF handle on-chain | `ILiquidityDensityFunction` + `bytes32 ldfParams` (what `(Int -> LiquidityDensityX96)` becomes) | note |

Rounding: Panoptic rounds long-closing amounts **up** (`getAmountsMoved`); `chunkAmount0/1` round down — one wei per leg, stated in tolerances.

**Off-chain surfaces (explicit):** `ErrorX96`, `windowTicks`, `Tuning`, `replicaError` — selection tooling (Foundry script / Haskell), not contracts. **On-chain twins:** `mixEll` (= Bunni LDF query), `binToLegs`, tokenId construction, `legLiquidity`.

## 4. Components and data flow

### Item 0 — prerequisites (must land first; small)

- **`asset` bit.** `PanopticMath.getLiquidityChunk` switches on `tokenId.asset(leg)` (bit 0 of each leg word), which `volOrderToTokenId` never writes → on-chain all four legs are token0 notional, while `legLiquidity` switches on `tokenType`. Add `addAsset`/`panopticAsset` (bit `legBase+0`) to `Panoptic.NId`; set **`asset = 1` on all four legs**; switch `legLiquidity` on `panopticAsset` with **Panoptic polarity** (`0 → getLiquidityForAmount0`, `1 → getLiquidityForAmount1`). This changes the current call-leg sizing (today token0 via `tokenType`) — the existing test `call leg amount0 = or·ΔQ` becomes `amount1 = or·ΔQ` for every leg; `legMintValue` keeps switching on `tokenType` (token received). Regression: all four fixture legs' liquidity equals the `asset`-branch formula.
- **`strikeAndRatio` without `Double` — scoped to the strike only:** \(k_{1/2} = \texttt{integerSqrt}(a\cdot b)\) (exists in `SqrtGrid`; unify with the private copy in `Greeks/Delta.hs`). `OptionRatio Double` stays as a budgeted leak — it is referenced from ~10 modules and is its own TODO. Existing identity test must stay green.
- **`mulDiv` helper** and the staged forms above.

### Item 1 — integer log (`feat`, not a fix)

`Payoffs.Log.lnQ96 :: SqrtPriceX96 -> SqrtPriceX96 -> PayoffX96` = \(2\cdot\ln(p_{1/2}/p^\star_{1/2})\) in Q96: port of Solady `FixedPointMathLib.lnWad` (int256, WAD) applied to \(\mathrm{mulDiv}(p_{1/2}, \mathrm{WAD}, p^\star_{1/2})\), rescaled WAD → Q96. Deliverables: algorithm, **measured** error bound (Solady gives none: report max wei error in WAD from the port's own test; argument floor error grows as \(\mathrm{WAD}/\text{ratio}\) on the put wing; negative operands: Haskell `div` floors, Solidity `/` truncates — pick floor and state it), tests: \(\ln 1 = 0\), monotone, agreement with the tick-quantized `nakedLogQ96` at exact tick prices within a stated Q96 tolerance, comparison vs `Double` only at the plot boundary. The tick version's error is \(\le \tfrac12\ln(1.0001) \approx 5\cdot10^{-5}\) in \(\ln(p/p^\star)\) — quoted against the binning error so the primitive is justified. `VariancePortfolio` switches to `lnQ96`; its API and plots are unchanged. Closes #36 (c).

### Item 2 — Phase 1: T1 replicates T0 (differential tests)

- `Liquidity.LiquidityGrid`: `BunniWeights`, `mixEll`, `ellSumX96`, `xiToAlpha8`, `validLadder`.
- `Payoffs.LadderPosition` (T1): `ladderChunks :: VolOrder -> (Int -> LiquidityDensityX96) -> TargetVega -> [LiquidityChunk]` (rungs from the `VolOrder` span; **validity predicate** instead of dropping rungs: \(\min_x \mathrm{mulDiv}(\Delta Q_v^\star, \ell(x), Q96) \ge 1\) and \(\min_x \ell(x) \ge Q96/10^3\), Bunni `MIN_LIQUIDITY_DENSITY`; invalid \(\theta\) is rejected, mass is never silently lost); `ladderReplica :: [LiquidityChunk] -> Tick -> Payoff SqrtPriceX96` \(= \sum_x h_x\) (hedged, \(i^\star\) argument selects the \(H_x\) branch); `ladderNotional` (\(\mathcal{N}_1\)).
- `ErrorX96`, `windowTicks :: VolOrder -> [Tick]`.
- **Differential tests** (\(\tilde{\mathrm{T1}}\) vs \(\tilde{\mathrm{T0}}\) on \(W\)):
  (a) ratio \(\tilde{\mathrm{T1}}/\tilde{\mathrm{T0}}\) flat over \(W\setminus\{p^\star\}\) within a stated relative tolerance; \(c\) reported;
  (b) `ErrorX96` (after fitting \(c\)) is **non-increasing within tolerance** over an enumerated set of \(\Delta_i\) dividing the span (finer rungs), and over an enumerated set of spans (wider);
  (c) at \(\xi^\star\) the error is \(\le\) that at \(\xi^\star\lambda^{\pm\Delta_i/4}\) and \(\xi^\star\lambda^{\pm\Delta_i/8}\) — **never** \(\xi^\star\lambda^{+\Delta_i/2} = 1\), which `mkXiX96` rejects; `Tuning` skips \(\xi = Q96\) explicitly — with a **pre-computed table** of \(e^\sigma_W\) at those points and the noise floor (Double/floor residue from §3) shown to be below the differences; if it is not, (c) is recorded as undecidable at that grid, not passed;
  (d) \(\hat\pi^\sigma_{\mathrm{T1}} = 0\) at \(p^\star\) (X96 tol), \(\ge 0\), midpoint-convex on samples.
- Plots (`outputs/Payoffs/Replica/`): `t1-ladder-density.png` (rungs + 4-bin overlay), `t1-vs-t0.png` (normalized overlay + difference panel), `t1-convergence.png`, `t1-xi-sweep.png`, `t1-vs-t0-vsGamma.png` / `-vsXi.png` (existing X-coordinate services), `t1-per-rung.png`.

### Item 3 — Phase 2: benchmark enters the legs module; tests are parameter tuning

- `Panoptic.Binning`: `binToLegs :: [LiquidityChunk] -> VolOrder -> ((Integer,Integer,Integer,Integer), TargetVega)` \(= \mathcal{B}\) on notional (returns \(\mathrm{or}\) **and** `positionSize`); `legNotionalX96` for round-trip; reject on \(\mathrm{or} < \mathrm{or}_{\min}\).
- `Payoffs.VolatilityReplica`: `replicaError :: [LiquidityChunk] {- T1 benchmark -} -> MintPlan {- T2 -} -> [Tick] -> ErrorX96`.
- `Tuning` (app-side, off-chain): grids over \(\xi_P, \xi_C\) (steps \(\lambda^{\pm\Delta_i/4}\) around `xiStar`), \(\omega\) (uint32 pairs), `VolRangeWidth`; returns \([(\theta, e^\sigma_W)]\), argmin, rejected set.
- **Tuning assertions** (benchmark fixed at T1(\(\xi^\star\))):
  (e) at \((\xi^\star, \xi^\star, \omega^\star)\) the T2 error \(\le\) at each of its grid neighbours;
  (f) over an enumerated set of `VolRangeWidth`, the truncation component is non-increasing within tolerance;
  (g) \(\mathcal{B}\) round-trip: \(\mathrm{or}(\mathrm{leg})\cdot\texttt{positionSize}\) reproduces \(n_{\mathrm{leg}}\) within \(1/(2\,\mathrm{or}(\mathrm{leg}))\) (max leg: \(<127\) wei), and `legLiquidity` output equals the \(c\)-weighted **mean** \(\sum_x L(i_x)c_x/\sum_x c_x\) — not the sum — within the same bound;
  (h) tuned \(\mathrm{or}\) beats the fixture \((1,2,3,4)\) at the same `VolOrder`.
- Plots: `t2-vs-t1.png`, `error-surface.png` (\((\xi_P,\xi_C)\) at best width), `width-sweep.png`.

**Data flow (Phase 2):** `VolOrder` → span, \(i^\star\), \(\iota_P,\iota_C\), `legIntervals` → \(\theta\) → `mixEll` → `ladderChunks` (T2's source density) → \(\mathcal{B}\) → \((\mathrm{or}, \texttt{positionSize})\) → `volOrderToMintPlan` → `legChunks` → `fourLegReplica` → `replicaError` vs `ladderReplica`(T1 at \(\xi^\star\)).

## 5. Error handling

- `mixEll`: \(w_0 + w_1 = 0\), \(\iota_g < 1\), \(\xi_g \le 0\) or \(= Q96\), rung index \(\notin [0,\iota)\) → `error` (as `ell`).
- `ladderChunks`: `validLadder` false → `Left`/`error` with the failing rung; never drops rungs.
- `binToLegs`: zero-mass bin or \(\mathrm{or} < \mathrm{or}_{\min}\) → reject (Panoptic `validate` reverts on 0); leg intervals via `legIntervals` guards.
- `ErrorX96`: empty \(W\) → `error`; \(\Delta Q_v^\star = 0\) impossible (`mkTargetVega`).
- `lnQ96`: \(p^\star_{1/2} = 0\) → `error`; regression at tick prices.
- `chunkAmount0/1`, `legLiquidity`: outputs uint128-checked.

## 6. Testing discipline

- Every new function ships with its test; X96 relative tolerances stated per test; no exact equality across branches; the §3 `Double` leaks are budgeted explicitly in each tolerance until closed.
- Gates: Item 0 (identity test + asset regression green) → Item 1 (log tests green, `VariancePortfolio` tests unchanged) → Item 2 (a)–(d) → Item 3 (e)–(h), each keeping all previous green.
- `stack build --ghc-options=-Werror && stack test` before every push (CI is `-Werror`).
- Plots regenerated and inspected at each gate; PNGs git-ignored.
- Bit-width table (per operation, for the Solidity twins) is a deliverable of Item 0.

## 7. Issue split (TODO #28)

0. `fix` — `asset` bit in `NId`/`LegChunk`; `strikeAndRatio` via `integerSqrt`; `mulDiv` + staged forms; bit-width table.
1. `feat` — `lnQ96` integer log; `VariancePortfolio` switches to it; closes #36 (c).
2. `feat` Phase 1 — `mixEll`, `validLadder`, `Payoffs.LadderPosition`, `ErrorX96`, tests (a)–(d), plots.
3. `feat` Phase 2 — `Panoptic.Binning`, `replicaError`, `Tuning`, tests (e)–(h), plots.
4. `docs` — README section binding T0/T1/T2, \(\theta_{\mathrm{LDF}}\), \(\mathcal{B}\), norm B, \(e^\sigma_W\).

Each: branch → issue → PR → cross-comments → merge.

## 8. Economic meaning

T1 is the LP book a variance-swap seller would hold on a Bunni pool: geometric liquidity decaying at \(\xi^\star = \lambda^{-\Delta_i/2}\) is the tick-resolution form of "replicating liquidity \(\propto K^{-1/2}\)". T2 is the same book as a Panoptic buyer can mint: four ranges, each a Uniswap chunk, sized by a 7-bit ratio times one `positionSize`. \(\theta_{\mathrm{LDF}}\) is the shape a vol desk tunes; \(\mathcal{B}\) is what the tokenId can carry (and what it loses: 7 bits per leg, one scale for all four); \(e^\sigma_W\) is the replication error the MEV tax later trades against arb extraction (README \(\inf_\tau|\pi^\sigma - \hat\pi^\sigma|\)). Norm C is where the desk's view of where price goes (\(m\)) reweights that error.

## 9. Out of scope

Norm C (needs #17–#18); \(\lambda_{X/M}\) LVR claim (#51); porting `sqrtPriceX96` to `getSqrtRatioAtTick` (budgeted, not done here); Solidity twins in `clamm-automaton` (the staged `mulDiv` forms make them transcription; `ErrorX96`/`Tuning` are off-chain by design).

## 10. Residual risks (accepted, from the second review pass)

- Ratio test (a) needs the exclusion band near \(p^\star\); tolerance set from the pre-computed noise table, not asserted.
- `OptionRatio Double` and `sqrtPriceX96` (`Double` power) remain leaks on every rung path until ported (`getSqrtRatioAtTick`); budgeted per tolerance.
- The `asset = 1` basis makes all four notionals token1; if a future design wants token0-based sizing, \(\mathcal{B}\) must be re-derived with \(c_x = (b_x-a_x)Q96/(a_xb_x)\) for **all** legs — never mixed.
- Panoptic `asset` semantics were read from `PanopticMath.sol:378–405` (vendored copy); re-verify against the pinned `lib/` before Item 0 lands.
