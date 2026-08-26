{-# LANGUAGE PatternSynonyms #-}

-- | T1 — the geometric liquidity ladder (README § REPLICATION_THEORY, Defs 4/6/7;
-- Lean lean/vol_markets/LadderLimit.lean, GeomMixture.lean; TODO #28 item 2).
--
-- Rungs i_x = i_L + x·Δ_i, x ∈ [0, ι); L(i_x) = mulDiv(ΔQ_υ*, ℓ(ξ*, ι; x), Q96);
-- hedged rung h_x(p) = H_x(p) − π^{ΔQ_X}(Id_{i_x}; p) with H_x = amount1 below i*,
-- p²·amount0 above (Lean `LadderLimit.hedgedRung`); T1(p) = Σ_x (L(i_x)/L_unit)·h_x(p)
-- (`ladderT1`); N_1 = Σ_x (L(i_x)/L_unit)·H_x(p*) (`ladderN1`).
-- Theorem 10 (`ladder_tendsto_logPortfolio_explicit`): T1/N_1 → c(S)·logPortfolio with
--   c(S) = 1 / (2·(ln λ·S/4 + (1 − λ^{−S/2})/2)),  S = span in ticks, strike at midpoint.
module Payoffs.LadderPosition
  ( Ladder(..)
  , ladderFromSpan
  , ladderChunks
  , hedgedRung
  , mintValue
  , ladderT1
  , ladderN1
  , ladderReturnQ96
  , logPortfolioQ96
  , cOfS
  , ladderLayout
  , ladderDensityLayout
  ) where

import Graphics.Rendering.Chart.Easy (Layout)

import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkAmount0
  , chunkAmount1
  , chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  , createChunk
  , unitLiquidity
  )
import Liquidity.LiquidityGrid
  ( LadderResolution
  , LiquidityDensityX96(..)
  , XiX96
  , ell
  , mkLadderResolution
  , unLadderResolution
  , xiStar
  )
import qualified Payoffs.CLMMPosition as CLMM
import Payoffs.Log (logPortfolioQ96)
import qualified Payoffs.Payoff as Payoff
import Plotting.PlotSqrt (PlotY(..), sqrtFunctionLayout)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPlot
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , mulDiv
  , pattern Q96
  , sqrtPriceX96
  , unTickSpacing
  )
import TargetVega (TargetVega, unTargetVega)

-- | A ladder: span, spacing, mint tick, target vega, profile ratio.
data Ladder = Ladder
  { ladderLo      :: Tick          -- i_L
  , ladderHi      :: Tick          -- i_U
  , ladderSpacing :: TickSpacing   -- Δ_i
  , ladderStar    :: Tick          -- i*
  , ladderVega    :: TargetVega    -- ΔQ_υ*
  , ladderXi      :: XiX96         -- ξ (default ξ*)
  }

-- | Ladder over [i_L, i_U] at ξ*; i_L, i_U, i* must be multiples of Δ_i and i_L < i* < i_U.
ladderFromSpan :: Tick -> Tick -> TickSpacing -> Tick -> TargetVega -> Ladder
ladderFromSpan lo hi sp star vega
  | lo >= hi || not (lo < star && star < hi) =
      error "Payoffs.LadderPosition.ladderFromSpan: need i_L < i* < i_U"
  | any (\t -> t `mod` d /= 0) [lo, hi, star] =
      error "Payoffs.LadderPosition.ladderFromSpan: i_L, i*, i_U must be multiples of Δ_i"
  | otherwise = Ladder lo hi sp star vega (xiStar sp)
  where d = unTickSpacing sp

iota :: Ladder -> LadderResolution
iota l = mkLadderResolution ((ladderHi l - ladderLo l) `div` unTickSpacing (ladderSpacing l))

rungTick :: Ladder -> Int -> Tick
rungTick l x = ladderLo l + x * unTickSpacing (ladderSpacing l)

-- | L(i_x) = mulDiv(ΔQ_υ*, ℓ(ξ, ι; x), Q96) as unit-spacing chunks; zero-liquidity rungs
-- are an error (Bunni: invalid params), never dropped.
ladderChunks :: Ladder -> [LiquidityChunk]
ladderChunks l =
  [ if liq <= 0 then error ("Payoffs.LadderPosition.ladderChunks: zero liquidity at rung " ++ show x)
               else createChunk i (i + d) liq
  | x <- [0 .. n - 1]
  , let i = rungTick l x
  , let LiquidityDensityX96 w = ell (ladderXi l) (iota l) x
  , let liq = mulDiv (unTargetVega (ladderVega l)) w Q96
  ]
  where
    n = unLadderResolution (iota l)
    d = unTickSpacing (ladderSpacing l)

-- | H_x(p): what the long rung holds after mint, in token1 at p (unit-liquidity chunk).
mintValue :: Tick -> LiquidityChunk -> SqrtPriceX96 -> PayoffX96
mintValue star ch (SqrtPriceX96 p)
  | chunkTickLower ch < star = chunkAmount1 ch
  | otherwise =
      let PayoffX96 am0 = chunkAmount0 ch
      in  PayoffX96 (mulDiv (mulDiv p p Q96) am0 Q96)

-- | h_x(p) = H_x(p) − π^{ΔQ_X}(Id; p) on a UNIT-liquidity chunk at the rung's ticks.
hedgedRung :: Tick -> LiquidityChunk -> SqrtPriceX96 -> PayoffX96
hedgedRung star ch p =
  let unitCh = createChunk (chunkTickLower ch) (chunkTickUpper ch) unitLiquidity
      PayoffX96 h = mintValue star unitCh p
      PayoffX96 principal = Payoff.runPayoff (CLMM.toPayoff (CLMM.fromChunk unitCh)) p
  in  PayoffX96 (h - principal)

-- | T1(p) = Σ_x (L(i_x)/L_unit) · h_x(p)   (Lean `ladderT1`), token1.
ladderT1 :: Ladder -> Payoff.Payoff SqrtPriceX96
ladderT1 l =
  Payoff.Payoff $ \p ->
    PayoffX96 $ sum
      [ mulDiv (chunkLiquidity ch) h unitLiquidity
      | ch <- ladderChunks l
      , let PayoffX96 h = hedgedRung (ladderStar l) ch p
      ]

-- | N_1 = Σ_x (L(i_x)/L_unit) · H_x(p*)   (Lean `ladderN1`), token1 mint notional.
ladderN1 :: Ladder -> PayoffX96
ladderN1 l =
  let pStar = sqrtPriceX96 (ladderStar l)
  in  PayoffX96 $ sum
        [ mulDiv (chunkLiquidity ch) h unitLiquidity
        | ch <- ladderChunks l
        , let unitCh = createChunk (chunkTickLower ch) (chunkTickLower ch + unTickSpacing (ladderSpacing l)) unitLiquidity
        , let PayoffX96 h = mintValue (ladderStar l) unitCh pStar
        ]

-- | T1(p)/N_1 in Q96 (dimensionless return).
ladderReturnQ96 :: Ladder -> SqrtPriceX96 -> PayoffX96
ladderReturnQ96 l p =
  let PayoffX96 t1 = Payoff.runPayoff (ladderT1 l) p
      PayoffX96 n1 = ladderN1 l
  in  PayoffX96 (mulDiv t1 Q96 n1)

-- | Theorem 10's constant c(S) = 1 / (2·(ln λ · S/4 + (1 − λ^{−S/2})/2)), Double (test/plot boundary).
cOfS :: Int -> Double
cOfS s =
  let lnLam = log 1.0001
      sD = fromIntegral s
  in  1 / (2 * (lnLam * sD / 4 + (1 - 1.0001 ** (negate sD / 2)) / 2))

-- | T1/N_1 vs c(S)·logPortfolio on one sqrt axis (Theorem 10 overlay).
ladderLayout :: SqrtPlot -> Ladder -> Layout Double Double
ladderLayout config l =
  let s = ladderHi l - ladderLo l
      c = cOfS s
      pStar = sqrtPriceX96 (ladderStar l)
      scaledT0 p = let PayoffX96 y = logPortfolioQ96 p pStar in PayoffX96 (floor (c * fromIntegral y))
  in  sqrtFunctionLayout config PayoffY
        [ ("T1/N_1 (ladder, ξ*)", ladderReturnQ96 l)
        , ("c(S)·logPortfolio (T0)", scaledT0)
        ]

-- | Rung liquidities L(i_x) as a step function of sqrt price.
ladderDensityLayout :: SqrtPlot -> Ladder -> Layout Double Double
ladderDensityLayout config l =
  let chs = ladderChunks l
      d = unTickSpacing (ladderSpacing l)
      at (SqrtPriceX96 p) =
        PayoffX96 $ sum [ chunkLiquidity ch
                        | ch <- chs
                        , let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
                        , let SqrtPriceX96 b = sqrtPriceX96 (chunkTickLower ch + d)
                        , a <= p && p < b ]
  in  sqrtFunctionLayout config PayoffY [ ("L(i_x) = ΔQ·ℓ(ξ*,ι;x)", at) ]
