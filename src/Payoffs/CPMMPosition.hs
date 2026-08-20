{-# LANGUAGE PatternSynonyms #-}

module Payoffs.CPMMPosition
  ( CPMMPosition
  , fromCall
  , fromPut
  , toPayoff
  , plotPayoff
  , cpmmEtaLayout
  , rhsPayoffLayout
  , fromDelta
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
  , tickFromSqrtPriceX96
  )
import Payoffs.PlotSqrt (PlotY(..), plotSqrtFunction, sqrtFunctionLayout)

import Pricing.PriceDeformation
  ( EtaX96
  , pattern BASE_ETA
  , deformedSqrtPriceX96
  )

import Greeks.Delta (DeltaX96, strikeFromDelta)
import StrikeX96 (StrikeX96(..))
import OptionRatio (OptionRatio(..))

-- | A single-tick CPMM LP payoff: call + range accrual = put + range accrual
-- (put-call parity in sqrt-price coordinates).
-- The constructor is opaque; same-strike is guaranteed by construction.
newtype CPMMPosition = CPMMPosition (Payoff.Payoff SqrtPriceX96)

-- | Construct from covered call + range accrual.
-- Asserts equality with the put path at the canonical witness p = kappa.
fromCall :: StrikeX96 -> OptionRatio -> CPMMPosition
fromCall k@(StrikeX96 kRaw) r =
  let callPath = Payoff.addPayoff (CC.coveredCall k)    (RAN.rangeAccrualNote k r)
      putPath  = Payoff.addPayoff (CSP.cashSecuredPut k) (RAN.rangeAccrualNote k r)
      witness  = SqrtPriceX96 kRaw
  in  assert
        ( Payoff.runPayoff callPath witness
          == Payoff.runPayoff putPath witness
        )
        (CPMMPosition callPath)

-- | Construct from cash-secured put + range accrual.
-- Asserts equality with the call path at the canonical witness p = kappa.
fromPut :: StrikeX96 -> OptionRatio -> CPMMPosition
fromPut k@(StrikeX96 kRaw) r =
  let callPath = Payoff.addPayoff (CC.coveredCall k)    (RAN.rangeAccrualNote k r)
      putPath  = Payoff.addPayoff (CSP.cashSecuredPut k) (RAN.rangeAccrualNote k r)
      witness  = SqrtPriceX96 kRaw
  in  assert
        ( Payoff.runPayoff callPath witness
          == Payoff.runPayoff putPath witness
        )
        (CPMMPosition putPath)

-- Kristensen (3.23): k_δ from spot, r, and Q96 delta; then fromCall.
fromDelta
  :: SqrtPriceX96
  -> OptionRatio
  -> DeltaX96
  -> CPMMPosition
fromDelta spot r d =
  fromCall (strikeFromDelta spot r d) r

toPayoff :: CPMMPosition -> Payoff.Payoff SqrtPriceX96
toPayoff (CPMMPosition p) = p

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

cpmmEtaLayout
  :: SqrtPlot
  -> StrikeX96
  -> OptionRatio
  -> [(String, EtaX96)]
  -> Layout Double Double
cpmmEtaLayout config k r labeledEtas =
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
    cpmm = toPayoff (fromCall k r)
  in
    sqrtFunctionLayout config PayoffY
      [ ("Covered Call", payoffAtEta BASE_ETA (CC.coveredCall k))
      , ("Range Accrual", payoffAtEta BASE_ETA (RAN.rangeAccrualNote k r))
      , ("CPMM η = 1/2", payoffAtEta BASE_ETA cpmm)
      , ("CPMM η = 2/3", payoffAtEta warpedEta cpmm)
      ]
