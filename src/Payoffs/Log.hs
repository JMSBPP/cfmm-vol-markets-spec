{-# LANGUAGE PatternSynonyms #-}

module Payoffs.Log
  ( nakedLogQ96
  , payoff
  , logContract
  ) where

import qualified Payoffs.Payoff as Payoff
import Payoffs.Forward (AtmForward, unAtmForward)
import Payoffs.NId (NId, scaleByNId)
import SqrtGrid
  ( SqrtPriceX96
  , PayoffX96(..)
  , pattern Q96
  , tickBase
  , tickFromSqrtPriceX96
  )

nakedLogQ96 :: SqrtPriceX96 -> AtmForward -> PayoffX96
nakedLogQ96 spot atm =
  let
    i = tickFromSqrtPriceX96 spot
    iStar = tickFromSqrtPriceX96 (unAtmForward atm)
  in
    PayoffX96 $
      floor
        ( fromIntegral Q96
            * fromIntegral (i - iStar)
            * log tickBase
        )

payoff :: NId -> SqrtPriceX96 -> AtmForward -> PayoffX96
payoff nId spot atm =
  let PayoffX96 naked = nakedLogQ96 spot atm
  in  PayoffX96 (scaleByNId nId naked)

logContract :: NId -> AtmForward -> Payoff.Payoff
logContract nId atm =
  Payoff.Payoff (\spot -> payoff nId spot atm)
