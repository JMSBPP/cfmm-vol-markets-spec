{-# LANGUAGE PatternSynonyms #-}

-- | π̂^σ — the option-replica volatility payoff as the 4-leg Panoptic position
-- (README "4-leg replica"; TODO #25 / #36).  Each long leg pays what it
-- received at mint minus the cost of returning the chunk's liquidity now:
--
--   π̂^σ(p) = Σ_leg [ H_leg(p) − π^φ(𝓛𝓒_leg; p) ]
--
-- with π^φ(𝓛𝓒; p) = CLMMPosition.fromChunk (the Uniswap principal in token1)
-- and the mint value H_leg, valued in token1 at the CURRENT price:
--   put  leg (tokenType 0): H = amount1(𝓛𝓒_leg)            (token1 received, constant)
--   call leg (tokenType 1): H = p² · amount0(𝓛𝓒_leg) / Q96  (token0 received, floats with p)
-- Legs are OTM at p*, so π̂^σ(p*) = 0 and π̂^σ ≥ 0 (each −π^φ is convex).
--
-- Sibling of Payoffs.VariancePortfolio (Hop A/B, the Carr–Madan continuum
-- limit) and Payoffs.VolatilityCall (π^σ, the contractual side).
module Payoffs.VolatilityReplica
  ( fourLegReplica
  , legMintValue
  , legPrincipal
  , legsLayout
  , replicaLayout
  , ErrorX96(..)
  , replicaError
  , windowTicks
  ) where

import Graphics.Rendering.Chart.Easy (Layout)

import Liquidity.LiquidityChunk (LiquidityChunk, chunkAmount0, chunkAmount1)
import Panoptic.LegChunk (legChunk)
import Panoptic.MintPlan (MintPlan(..), fourLegNumLegs)
import Panoptic.NId (panopticTokenType)
import qualified Payoffs.CLMMPosition as CLMM
import qualified Payoffs.Payoff as Payoff
import Plotting.PlotSqrt (PlotY(..), sqrtFunctionLayout)
import SqrtGrid (PayoffX96(..), SqrtPlot, SqrtPriceX96(..), Tick, integerSqrt, mulDiv, pattern Q96, sqrtPriceX96)
import Payoffs.LadderPosition (Ladder(..), ladderN1, ladderT1)
import Volatility.VolOrder (VolOrder, tickBucketFromVolOrder)

-- | π^φ(𝓛𝓒_leg; p).
legPrincipal :: LiquidityChunk -> SqrtPriceX96 -> PayoffX96
legPrincipal ch = Payoff.runPayoff (CLMM.toPayoff (CLMM.fromChunk ch))

-- | H_leg(p): what the long leg holds after the mint, valued in token1 at p.
legMintValue :: MintPlan -> Int -> SqrtPriceX96 -> PayoffX96
legMintValue plan leg (SqrtPriceX96 p)
  | panopticTokenType (mintTokenId plan) (toInteger leg) == 0 = chunkAmount1 ch
  | otherwise =
      let PayoffX96 am0 = chunkAmount0 ch
      in  PayoffX96 $ mulDiv (mulDiv p p Q96) am0 Q96   -- two mulDivs: p²/Q96 ≤ 2^224, × am0 ≤ 2^128
  where
    ch = legChunk plan leg

-- | π̂^σ(p) = Σ_leg [ H_leg(p) − π^φ(𝓛𝓒_leg; p) ].  The p* argument is the
-- mint price; it is asserted to be OTM for every leg by construction of the
-- VolOrder geometry (puts below i*, calls above), so the sum is 0 there.
fourLegReplica :: MintPlan -> SqrtPriceX96 -> Payoff.Payoff SqrtPriceX96
fourLegReplica plan _pStar =
  Payoff.Payoff $ \p ->
    PayoffX96 $ sum
      [ h - principal
      | leg <- [0 .. fourLegNumLegs (mintTokenId plan) - 1]
      , let PayoffX96 h = legMintValue plan leg p
      , let PayoffX96 principal = legPrincipal (legChunk plan leg) p
      ]

-- | Per-leg replica terms H_leg(p) − π^φ(LC_leg; p) and their sum (= π̂^σ)
-- on one sqrt axis.
legsLayout :: SqrtPlot -> MintPlan -> Layout Double Double
legsLayout config plan =
  sqrtFunctionLayout config PayoffY $
    [ ("leg " ++ show leg ++ " H − π^φ(LC_leg)", legTerm leg)
    | leg <- [0 .. fourLegNumLegs (mintTokenId plan) - 1]
    ]
    ++ [ ("Σ_leg = π̂^σ", Payoff.runPayoff (fourLegReplica plan (SqrtPriceX96 0))) ]
  where
    legTerm leg p =
      let PayoffX96 h = legMintValue plan leg p
          PayoffX96 principal = legPrincipal (legChunk plan leg) p
      in  PayoffX96 (h - principal)

-- | π̂^σ against a reference curve (e.g. Hop B Carr–Madan) on one sqrt axis.
replicaLayout
  :: SqrtPlot
  -> MintPlan
  -> SqrtPriceX96
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> Layout Double Double
replicaLayout config plan pStar references =
  sqrtFunctionLayout config PayoffY $
    ("π̂^σ 4-leg replica", Payoff.runPayoff (fourLegReplica plan pStar)) : references

-- | e^σ_W (README § REPLICATION_THEORY Def 8): RMS over W of (T2 − T1)/N_1, Q96.
-- Residuals are normalized by the token1 mint notional N_1 BEFORE squaring
-- (dimensionless, O(1) on W); sum; integerSqrt back to Q96.  Off-chain surface.
newtype ErrorX96 = ErrorX96 Integer
  deriving (Show, Eq, Ord)

replicaError :: Ladder -> MintPlan -> [Tick] -> ErrorX96
replicaError lad plan w
  | null w = error "Payoffs.VolatilityReplica.replicaError: empty window"
  | otherwise =
      let PayoffX96 n1 = ladderN1 lad
          pStar = sqrtPriceX96 (ladderStar lad)
          t1 = ladderT1 lad
          t2 = fourLegReplica plan pStar
          sq = sum [ d * d
                   | i <- w
                   , let p = sqrtPriceX96 i
                   , let PayoffX96 a = Payoff.runPayoff t2 p
                   , let PayoffX96 b = Payoff.runPayoff t1 p
                   , let d = mulDiv (a - b) Q96 n1 ]
      in  ErrorX96 (integerSqrt (sq `div` toInteger (length w)))

-- | W = every `stride`-th tick on 3× the VolOrder span, [i_L − S, i_U + S].
windowTicks :: VolOrder -> Int -> [Tick]
windowTicks vo stride =
  let (iL, iU, _) = tickBucketFromVolOrder vo
      s = iU - iL
  in  [iL - s, iL - s + stride .. iU + s]
