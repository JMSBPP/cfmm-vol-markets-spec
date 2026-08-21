{-# LANGUAGE PatternSynonyms #-}

module Payoffs.Payoff
  ( Payoff(..)
  , addPayoff
  , subPayoff
  , scalePayoff
  , applyStrikeVariation
  , squareSqrtPrice
  ) where

import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , pattern Q96
  )

import StrikeX96
  ( StrikeSlope(..)
  , StrikeVariation(..)
  )

import Panoptic.NId (NId, scaleByNId)

squareSqrtPrice :: SqrtPriceX96 -> PayoffX96
squareSqrtPrice (SqrtPriceX96 sqrtPrice) =
  PayoffX96 $
    (sqrtPrice * sqrtPrice) `div` Q96

newtype Payoff u = Payoff
  { runPayoff :: u -> PayoffX96
  }

addPayoff :: Payoff u -> Payoff u -> Payoff u
addPayoff (Payoff payoff1) (Payoff payoff2) =
  Payoff $ \underlying ->
    let
      PayoffX96 value1 = payoff1 underlying
      PayoffX96 value2 = payoff2 underlying
    in
      PayoffX96 (value1 + value2)

subPayoff :: Payoff u -> Payoff u -> Payoff u
subPayoff (Payoff payoff1) (Payoff payoff2) =
  Payoff $ \underlying ->
    let
      PayoffX96 value1 = payoff1 underlying
      PayoffX96 value2 = payoff2 underlying
    in
      PayoffX96 (value1 - value2)

scalePayoff :: NId -> Payoff u -> Payoff u
scalePayoff nId (Payoff pf) =
  Payoff $ \underlying ->
    let PayoffX96 value = pf underlying
    in  PayoffX96 (scaleByNId nId value)

applyStrikeVariation
  :: Payoff SqrtPriceX96
  -> (SqrtPriceX96 -> StrikeSlope)
  -> StrikeVariation
  -> Payoff SqrtPriceX96
applyStrikeVariation
  (Payoff payoff)
  strikeDerivative
  (StrikeVariation deltaK) =
    Payoff $ \sqrtPrice ->
      let
        PayoffX96 payoffValue = payoff sqrtPrice
        StrikeSlope slope = strikeDerivative sqrtPrice
        variation = round (fromInteger deltaK * slope)
      in
        PayoffX96 (payoffValue + variation)
