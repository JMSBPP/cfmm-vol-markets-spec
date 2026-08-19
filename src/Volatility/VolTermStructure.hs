{-# LANGUAGE PatternSynonyms #-}

module Volatility.VolTermStructure
  ( Step(..)
  , unStep
  , InstantaneousVol(..)
  , unInstantaneousVol
  , VolTermStructure(..)
  , BarL(..)
  , unBarL
  , FlowVol(..)
  , unFlowVol
  , cevDeltaCpmm
  , cevFromPhi
  ) where

import Pricing.PriceDeformation (EtaX96(..), pattern BASE_ETA)
import SqrtGrid (Tick, sqrtPrice)

newtype Step = Step Int
  deriving (Show, Eq)

unStep :: Step -> Int
unStep (Step t) = t

newtype InstantaneousVol = InstantaneousVol Double
  deriving (Show, Eq)

unInstantaneousVol :: InstantaneousVol -> Double
unInstantaneousVol (InstantaneousVol s) = s

data VolTermStructure = VolTermStructure
  { volAt :: Tick -> Step -> InstantaneousVol
  }

newtype BarL = BarL Double
  deriving (Show, Eq)

unBarL :: BarL -> Double
unBarL (BarL x) = x

newtype FlowVol = FlowVol Double
  deriving (Show, Eq)

unFlowVol :: FlowVol -> Double
unFlowVol (FlowVol x) = x

cevDeltaCpmm :: BarL -> FlowVol -> Double
cevDeltaCpmm (BarL barL) (FlowVol sigmaF)
  | barL <= 0 || sigmaF <= 0 =
      error "Volatility.VolTermStructure.cevDeltaCpmm: L̄ and σ_F must be > 0"
  | otherwise = 2 * sigmaF / barL

cevFromPhi :: EtaX96 -> BarL -> FlowVol -> VolTermStructure
cevFromPhi eta barL flowVol
  | eta /= BASE_ETA =
      error "Volatility.VolTermStructure.cevFromPhi: only BASE_ETA this round"
  | unBarL barL <= 0 =
      error "Volatility.VolTermStructure.cevFromPhi: L̄ must be > 0"
  | unFlowVol flowVol <= 0 =
      error "Volatility.VolTermStructure.cevFromPhi: σ_F must be > 0"
  | otherwise =
      let delta = cevDeltaCpmm barL flowVol
      in  VolTermStructure $ \i _ ->
            InstantaneousVol (delta / sqrtPrice i)
