{-# LANGUAGE PatternSynonyms #-}

-- | λ_{X/M} — per-token LVR rate (README MODEL_CLOSURE §2, issue #51 / TODO #26).
--
-- χ(𝓛𝓒) (Prop 3) is EXACT from Theorem 5 and Def 12:
--   ∫_{a²}^{b²} ∂²π^{ΔQ_X}/∂P² dP = ∂_P π(b²) − ∂_P π(a²) = 0 − amount0(𝓛𝓒),
-- so the in-range gamma exposure is the chunk's amount0 (raw token0): the total
-- delta the chunk sheds across its range.  `chi = chunkAmount0`.
--
-- Per correction segment [lo, hi] inside a chunk, marked at the corrected price p_j
-- (Prop 4): LVR_net = amount_in·[p_j²/(lo·hi) − 1 − φ]; when the segment ends at p_j this
-- is amount_in·[(r½ − 1) − φ], r½ = hi/lo — the arb captures the SQRT-price return, i.e.
-- half the price gap, so the rational trigger is a gap of 2φ ticks (`rationalBandTicks`).
-- A chunk covering only the tail of a wide correction earns p_j²/(lo·hi) − 1 < φ on that
-- segment: a 4-leg position can lose on marginal segments even under the rational band;
-- a chunk covering the whole path cannot (`lvrRateOn` with a wide chunk).
--
-- The rate is measured ex post on the composed path with the holder inactive
-- (Payoffs.HolderPath): λ(s, φ) = LVR_net / Σ amount_in over arb segments, both token1,
-- summed over the chunks — the same dimensionless rate as Prop 4, reported in PIPS
-- (uint24, 1e6 = 1, the FeePips convention, so λ and φ share an axis).
-- s = external step (ticks / round); band = the arb trigger in ticks (naive φ/100
-- crosses zero at 2φ; rational 2φ/100 is ≥ 0 on continuous liquidity).
module Payoffs.LvrRate
  ( chi
  , naiveBandTicks
  , rationalBandTicks
  , lvrRate
  , lvrRateOn
  , lvrRateTable
  ) where

import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0)
import Panoptic.LegChunk (legChunks)
import Panoptic.MintPlan (MintPlan)
import Payoffs.HolderPath (Regime(..), composedPath)
import Payoffs.PathAccrual (Accrual(..), Step(..), Tag(..), addAccrual, pathAccrual, pattern PIPS_ONE, stepVolume1, zeroAccrual)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), Tick, mulDiv)

-- | χ(𝓛𝓒) = amount0(𝓛𝓒), raw token0.
chi :: LiquidityChunk -> Integer
chi ch = let PayoffX96 a = chunkAmount0 ch in a

-- | Price-gap band equal to the fee: φ pips / 100 ticks (1 tick = 1 bp).
naiveBandTicks :: FeePips -> Int
naiveBandTicks phi = fromInteger (unFeePips phi `div` 100)

-- | Rational arb trigger from Prop 4: the sqrt-price return must exceed φ ⇒ gap > 2φ ticks.
rationalBandTicks :: FeePips -> Int
rationalBandTicks = (2 *) . naiveBandTicks

-- | λ(s; φ, band) on the composed path (seed, i0, n rounds, trans amplitude): pips (signed).
lvrRate :: Int -> Tick -> Int -> Int -> FeePips -> Int -> MintPlan -> Int -> Integer
lvrRate seed i0 n transAmp phi band plan = lvrRateOn seed i0 n transAmp phi band (legChunks plan)

-- | Same on an explicit chunk list (a single wide chunk = continuous liquidity over the path).
lvrRateOn :: Int -> Tick -> Int -> Int -> FeePips -> Int -> [LiquidityChunk] -> Int -> Integer
lvrRateOn seed i0 n transAmp phi band chs s =
  let path  = composedPath seed i0 n transAmp s (Regime 1 band False)
      acc   = foldr addAccrual zeroAccrual [ pathAccrual phi phi ch path | ch <- chs ]
      nuArb = sum [ stepVolume1 ch st | ch <- chs, st <- path, stepTag st == Arb ]
      net   = lvrGross acc - feesArb acc
  in  if nuArb == 0 then 0 else mulDiv net PIPS_ONE nuArb

lvrRateTable :: Int -> Tick -> Int -> Int -> FeePips -> Int -> MintPlan -> [Int] -> [(Integer, Integer)]
lvrRateTable seed i0 n transAmp phi band plan ss = [ (toInteger s, lvrRate seed i0 n transAmp phi band plan s) | s <- ss ]
