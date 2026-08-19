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

import Payoffs.NId (NId, scaleByNId)

---------------------------------------------
-- Later generalization requires:	   --
-- same underlying coordinate 	           --
-- newtype Payoff underlying payoff =	   --
--   Payoff				   --
--     { runPayoff :: underlying -> payoff --
--     }				   --
---------------------------------------------

squareSqrtPrice :: SqrtPriceX96 -> PayoffX96

squareSqrtPrice (SqrtPriceX96 sqrtPrice) =
  PayoffX96 $
    (sqrtPrice * sqrtPrice) `div` Q96


newtype Payoff =
  Payoff
    { runPayoff :: SqrtPriceX96 -> PayoffX96
    }


addPayoff :: Payoff -> Payoff -> Payoff


addPayoff (Payoff payoff1) (Payoff payoff2) =
    Payoff $ \price ->
     let
        PayoffX96 value1 =
          payoff1 price

        PayoffX96 value2 =
          payoff2 price

      in
        PayoffX96 (value1 + value2)


subPayoff :: Payoff -> Payoff -> Payoff
subPayoff (Payoff payoff1) (Payoff payoff2) =
    Payoff $ \price ->
     let
        PayoffX96 value1 =
          payoff1 price

        PayoffX96 value2 =
          payoff2 price

      in
        PayoffX96 (value1 - value2)


scalePayoff :: NId -> Payoff -> Payoff
scalePayoff nId (Payoff pf) =
    Payoff $ \price ->
      let PayoffX96 value = pf price
      in  PayoffX96 (scaleByNId nId value)


applyStrikeVariation
  :: Payoff
  -> (SqrtPriceX96 -> StrikeSlope)
  -> StrikeVariation
  -> Payoff

applyStrikeVariation
  (Payoff payoff)
  strikeDerivative
  (StrikeVariation deltaK) =
    Payoff $ \sqrtPrice ->

      let
        PayoffX96 payoffValue =
          payoff sqrtPrice

        StrikeSlope slope =
          strikeDerivative sqrtPrice

        variation =
          round (fromInteger deltaK * slope)

      in
        PayoffX96
          (payoffValue + variation)