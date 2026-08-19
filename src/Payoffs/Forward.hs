{-# LANGUAGE PatternSynonyms #-}

module Payoffs.Forward
  ( AtmForward(..)
  , unAtmForward
  , nakedForwardQ96
  , payoff
  , forward
  ) where

import qualified Payoffs.Payoff as Payoff
import Payoffs.NId (NId, scaleByNId)
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , pattern Q96
  )

newtype AtmForward = AtmForward SqrtPriceX96
  deriving (Show, Eq)

unAtmForward :: AtmForward -> SqrtPriceX96
unAtmForward (AtmForward s) = s

nakedForwardQ96 :: SqrtPriceX96 -> AtmForward -> PayoffX96
nakedForwardQ96 spot (AtmForward star) =
  let
    PayoffX96 p = Payoff.squareSqrtPrice spot
    PayoffX96 k = Payoff.squareSqrtPrice star
  in
    if k <= 0
      then error "Payoffs.Forward.nakedForwardQ96: P* must be > 0"
      else PayoffX96 $ ((p - k) * Q96) `div` k

payoff :: NId -> SqrtPriceX96 -> AtmForward -> PayoffX96
payoff nId spot atm =
  let PayoffX96 naked = nakedForwardQ96 spot atm
  in  PayoffX96 (scaleByNId nId naked)

forward :: NId -> AtmForward -> Payoff.Payoff
forward nId atm =
  Payoff.Payoff (\spot -> payoff nId spot atm)
