# Bit widths of the fixed-point chains (Solidity twin transcription table)

Spec: `docs/superpowers/specs/2026-08-24-scratchpad-ladder-replication-design.md` §3, Item 0.
Rule: every product/quotient below is written in the Haskell exactly as the Solidity twin stages it,
using `SqrtGrid.mulDiv` (single floor; twin = 512-bit `FullMath.mulDiv`). Haskell `Integer` never
overflows — this table is what the EVM twin must respect. Bare `a*b*c \`div\` d` is forbidden in new code.

Operand ranges: sqrt prices `a, b, p` ≤ 2^160 (Q64.96); liquidity `L` ≤ 2^128; `Q96 = 2^96`;
`amt` (or·positionSize) ≤ 127·2^128 < 2^135; rung/leg widths `b − a` < 2^160.

| function | Haskell (staged) | Solidity twin | intermediate max | note |
|---|---|---|---|---|
| `chunkAmount0` | `mulDiv (L*Q96) (b−a) b \`div\` a` | `Math.getAmount0ForLiquidity`: `mulDiv(L << 96, b − a, b) / a` | `(L<<96)·(b−a)` ≤ 2^384 | needs 512-bit mulDiv; second `/ a` is a plain division; result cast `toUint128` (`checkU128`) |
| `chunkAmount1` | `mulDiv L (b−a) Q96` | `Math.getAmount1ForLiquidity`: `mulDiv(L, b − a, Q96)` | `L·(b−a)` ≤ 2^288 | 512-bit mulDiv; `toUint128` |
| `legLiquidity` (asset = 1) | `mulDiv amt Q96 (b−a)` | `Math.getLiquidityForAmount1`: `mulDiv(amt, Q96, b − a)` | `amt·Q96` ≤ 2^231 | fits 256; result `toUint128` (uint128 guard in `createChunk`) |
| `legLiquidity` (asset = 0) | `mulDiv amt (mulDiv a b Q96) (b−a)` | `Math.getLiquidityForAmount0`: `mulDiv(amt, mulDiv96(a, b), b − a)` | `a·b` ≤ 2^320; `amt·(ab/Q96)` ≤ 2^359 | both stages 512-bit; **not** bit-equal to single `amt·a·b/((b−a)Q96)` — the staged form is canonical |
| `legMintValue` (call) | `mulDiv (mulDiv p p Q96) am0 Q96` | two `mulDiv`s | `p²` ≤ 2^320; `(p²/Q96)·am0` ≤ 2^352 | 512-bit both stages |
| `chunkPrincipal` in-range (via `fromChunk`) | `amount0 · [CC + RAN] / Q96` | `PositionValue.principal` (amounts at current price) | `am0·payoff` ≤ 2^128·2^224 = 2^352 | on-chain twin is the amounts route, not the CLMM identity; identity is for tests |
| `ell` (geometric weight) | `xiPow · (Q96 − ξ) / (Q96 − ξ^ι)` (existing) | `LibGeometricDistribution.liquidityDensityX96` | ≤ 2^192 | Bunni uses `mulDiv`/`fullMulDiv` by branch; equal results at these magnitudes |
| rung liquidity `L(i_x)` | `mulDiv ΔQ ℓ Q96` | `positionSize`-style scaling | `ΔQ·ℓ` ≤ 2^224 | fits 256 |
| binning `n_leg` | `Σ mulDiv L_x c_x Q96`, `c_x = b_x − a_x` | off-chain / view | ≤ 2^288 per term | `positionSize = n_max / 127` must be < 2^128 → require `n_max < 2^135` |
| `ErrorX96` | `mulDiv d Q96 N_1`, square, sum, `integerSqrt` | **off-chain only** | unbounded on-chain | no EVM bound claimed |
| `principalDelta` (∂_P principal = token0 held) | `mulDiv (L·Q96) (b − p̄) b `div` p̄`, p̄ = clamp(p; a, b) | `getAmount0ForLiquidity` at (p̄, b) | `L·Q96` ≤ 2^224 | fits 256; result < 2^128 |
| `deltaOfPayoff` (generic ∂_P) | `mulDiv (ΔV) Q96 (ΔP)` | **off-chain / tests only** | `ΔV·Q96` ≤ 2^224 | signed; twin is the closed form, not the difference |
| `hedgeStep` value1 / fee | `mulDiv (mulDiv p p Q96) |q*| Q96`, then `mulDiv value1 φ 1e6` | `getAmountsMoved`-style valuation + fee | `p²` ≤ 2^320; `(p²/Q96)·|q*|` ≤ 2^352 | 512-bit both stages; `q*` < 2^128 |
| `stepVolume1` / `lvrRateOn` | `mulDiv (mulDiv pj pj Q96) amt0 Q96`; `mulDiv net PIPS_ONE nuArb` | `getAmountsMoved` valuation; off-chain rate | `pj²` ≤ 2^320; `net·1e6` ≤ 2^148 | rate is a uint24-pips view, signed off-chain |
| `lnQ96` (Item 1) | port of Solady `lnWad` on `mulDiv p WAD p*`, then `mulDiv (2·ln) Q96 WAD` | `FixedPointMathLib.lnWad` | int256 | signed: floor (Haskell `div`) vs truncate (Solidity `/`) — floor chosen |

Rounding direction: `chunkAmount0/1` round **down**; Panoptic rounds long-closing amounts **up** (`getAmountsMoved`).
One-wei-per-leg drift, budgeted in the X96 tolerances.

Known `Double` leaks still on the path (budgeted, not claimed away): `OptionRatio` (`b/a` as `Double`, ~10 modules),
`sqrtPriceX96` (`Double` power vs `getSqrtRatioAtTick`), `Log.nakedLogQ96` until Item 1.
