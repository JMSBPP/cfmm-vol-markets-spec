{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Payoffs.CLMMPosition'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.CLMMPosition
  ( scaledVsUnitLayout
  , plotPayoff
  , clmmEtaLayout
  , rhsPayoffLayout
  ) where

import Control.Exception (assert)
import qualified Payoffs.Payoff as Payoff
import qualified Payoffs.CoveredCall as CC
import qualified Payoffs.CashSecuredPut as CSP
import qualified Payoffs.RangeAccrualNote as RAN
import Graphics.Rendering.Chart.Easy (Layout)
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  , integerSqrt
  , pattern Q96
  , sqrtPriceX96
  , tickFromSqrtPriceX96
  )
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction, sqrtFunctionLayout)
import Pricing.PriceDeformation
  ( EtaX96
  , pattern BASE_ETA
  , deformedSqrtPriceX96
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
import Payoffs.CLMMPosition


plotPayoff :: FilePath -> SqrtPlot -> StrikeX96 -> OptionRatio -> IO ()
plotPayoff path config k r =
  plotSqrtFunction path config PayoffY
    [ Payoff.runPayoff (toPayoff (fromCall k r))
    , Payoff.runPayoff (toPayoff (fromPut  k r))
    ]

-- x = undeformed p_{1/2}(i); y = π(p_{1/2}(i; η))
payoffAtEta
  :: EtaX96
  -> Payoff.Payoff SqrtPriceX96
  -> SqrtPriceX96
  -> PayoffX96
payoffAtEta eta payoff sample =
  case deformedSqrtPriceX96 eta (tickFromSqrtPriceX96 sample) of
    Nothing -> PayoffX96 0
    Just deformed -> Payoff.runPayoff payoff deformed

clmmEtaLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> [(String, EtaX96)]
  -> Layout Double Double
clmmEtaLayout config k r labeledEtas =
  let
    position = toPayoff (fromCall k r)
  in
    sqrtFunctionLayout config PayoffY
      [ (label, payoffAtEta eta position)
      | (label, eta) <- labeledEtas
      ]

rhsPayoffLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> EtaX96
  -> Layout Double Double
rhsPayoffLayout config k r warpedEta =
  let
    clmm = toPayoff (fromCall k r)
  in
    sqrtFunctionLayout config PayoffY
      [ ("Covered Call", payoffAtEta BASE_ETA (CC.coveredCall k))
      , ("Range Accrual", payoffAtEta BASE_ETA (RAN.rangeAccrualNote k r))
      , ("CLMM η = 1/2", payoffAtEta BASE_ETA clmm)
      , ("CLMM η = 2/3", payoffAtEta warpedEta clmm)
      ]

-- | Scaled (chunk principal) vs unit (per token0 notional) on one sqrt axis.
scaledVsUnitLayout
  :: SqrtPlot
  -> LiquidityChunk
  -> Layout Double Double
scaledVsUnitLayout config ch =
  let (k, r) = strikeAndRatio ch
      unit   = fromCall k r
  in  sqrtFunctionLayout config PayoffY
        [ ("CLMM unit (amount0 = 1 token0)", Payoff.runPayoff (toPayoff unit))
        , ("CLMM × amount0 (chunk principal)", Payoff.runPayoff (toPayoff (fromChunk ch)))
        ]
