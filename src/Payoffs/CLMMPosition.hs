{-# LANGUAGE PatternSynonyms #-}

module Payoffs.CLMMPosition
  ( CLMMPosition
  , clmmChunk
  , chunkStrike
  , fromChunk
  , fromCall
  , fromPut
  , chunkFromStrike
  , strikeAndRatio
  , toPayoff
  , fromDelta
  ) where

import Control.Exception (assert)

import qualified Payoffs.Payoff as Payoff
import qualified Payoffs.CoveredCall as CC
import qualified Payoffs.CashSecuredPut as CSP
import qualified Payoffs.RangeAccrualNote as RAN

import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , integerSqrt
  , pattern Q96
  , sqrtPriceX96
  , tickFromSqrtPriceX96
  )

import Greeks.Delta (DeltaX96, strikeFromDelta)
import StrikeX96 (StrikeX96(..))
import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkAmount0
  , chunkTickLower
  , chunkTickUpper
  , createChunk
  )
import OptionRatio (OptionRatio(..))

-- | A CLMM LP position IS a liquidity chunk 𝓛𝓒 = (i⁻, i⁺, L): the chunk fixes
-- location (k½ = √(p^bid p^ask), r = p^ask/p^bid, sqrt-price ratio) AND scale
-- (its token0 amount).  Payoff = amount0(𝓛𝓒) · [π^{c|p}(k½) + π^RAN(k½, r)]
-- — the per-tick CLMM identity (README, TODO #24 / #35 / #27); this equals the
-- Uniswap V3 principal (v3-periphery PositionValue.principal) valued in token1.
-- call + RAN = put + RAN (put-call parity in sqrt coordinates); the
-- constructor is opaque, same-chunk is guaranteed by construction.
data CLMMPosition = CLMMPosition
  { clmmChunk  :: LiquidityChunk
  , clmmPayoff :: Payoff.Payoff SqrtPriceX96
  }

-- k½ = integerSqrt(a·b) — no Double on the strike (TODO #28 item 0).
-- The ratio r = b/a stays an OptionRatio Double: a budgeted leak, own TODO.
strikeAndRatio :: LiquidityChunk -> (StrikeX96, OptionRatio)
strikeAndRatio ch =
  let SqrtPriceX96 a = sqrtPriceX96 (chunkTickLower ch)
      SqrtPriceX96 b = sqrtPriceX96 (chunkTickUpper ch)
  in  (StrikeX96 (integerSqrt (a * b)), OptionRatio (fromInteger b / fromInteger a))

chunkStrike :: LiquidityChunk -> StrikeX96
chunkStrike = fst . strikeAndRatio

scaleQ96 :: PayoffX96 -> Payoff.Payoff SqrtPriceX96 -> Payoff.Payoff SqrtPriceX96
scaleQ96 (PayoffX96 s) (Payoff.Payoff f) =
  Payoff.Payoff $ \spot ->
    let PayoffX96 y = f spot
    in  PayoffX96 ((s * y) `div` Q96)

-- | Canonical constructor: the position of a chunk.
-- Asserts call-path == put-path at the witness p = k½.
fromChunk :: LiquidityChunk -> CLMMPosition
fromChunk ch =
  let (k@(StrikeX96 kRaw), r) = strikeAndRatio ch
      callPath = Payoff.addPayoff (CC.coveredCall k)    (RAN.rangeAccrualNote k r)
      putPath  = Payoff.addPayoff (CSP.cashSecuredPut k) (RAN.rangeAccrualNote k r)
      witness  = SqrtPriceX96 kRaw
  in  assert
        ( Payoff.runPayoff callPath witness
          == Payoff.runPayoff putPath witness
        )
        (CLMMPosition ch (scaleQ96 (chunkAmount0 ch) callPath))

-- | Kristensen-side entry: the UNIT chunk for (k½, r) — ticks snapped to the
-- grid (i⁻ = tick(k½/√r), i⁺ = tick(k½√r)) and liquidity L = a·b/(b−a) so that
-- amount0 = Q96 (one token0).  Payoff per unit of token0 notional, exactly
-- the historical fromCall normalization on-grid.
chunkFromStrike :: StrikeX96 -> OptionRatio -> LiquidityChunk
chunkFromStrike (StrikeX96 kRaw) (OptionRatio r)
  | lo >= hi  = error "Payoffs.CLMMPosition.chunkFromStrike: (k, r) must span at least one tick"
  | otherwise = createChunk lo hi ((a * b) `div` (b - a))
  where
    sqrtR = sqrt r
    lo = tickFromSqrtPriceX96 (SqrtPriceX96 (floor (fromInteger kRaw / sqrtR)))
    hi = tickFromSqrtPriceX96 (SqrtPriceX96 (floor (fromInteger kRaw * sqrtR)))
    SqrtPriceX96 a = sqrtPriceX96 lo
    SqrtPriceX96 b = sqrtPriceX96 hi

-- | Construct from covered call + range accrual on the unit chunk of (k, r).
fromCall :: StrikeX96 -> OptionRatio -> CLMMPosition
fromCall k r = fromChunk (chunkFromStrike k r)

-- | Construct from cash-secured put + range accrual — same chunk, same payoff
-- (parity is asserted inside fromChunk).
fromPut :: StrikeX96 -> OptionRatio -> CLMMPosition
fromPut = fromCall

-- Kristensen (3.23): k_δ from spot, r, and Q96 delta; then fromCall.
fromDelta
  :: SqrtPriceX96
  -> OptionRatio
  -> DeltaX96
  -> CLMMPosition
fromDelta spot r d =
  fromCall (strikeFromDelta spot r d) r

toPayoff :: CLMMPosition -> Payoff.Payoff SqrtPriceX96
toPayoff = clmmPayoff
