module Payoffs.CashSecuredPut
  ( payoff
  , cashSecuredPut
  , strikeDerivative
  , plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff
import qualified StrikeX96 as Strike

import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  , plotSqrtFunction
  )

payoff
  :: SqrtPriceX96
  -> Strike.StrikeX96
  -> PayoffX96
payoff
  sqrtPrice
  (Strike.StrikeX96 strikePrice) =
    let
      PayoffX96 p = Payoff.squareSqrtPrice sqrtPrice
      PayoffX96 k = Payoff.squareSqrtPrice (SqrtPriceX96 strikePrice)
    in
      PayoffX96 $
        k - max (k - p) 0

strikeDerivative
  :: Strike.StrikeX96
  -> SqrtPriceX96
  -> Strike.StrikeSlope
strikeDerivative
  (Strike.StrikeX96 strikePrice)
  sqrtPrice
  | Payoff.squareSqrtPrice sqrtPrice
      < Payoff.squareSqrtPrice (SqrtPriceX96 strikePrice) =
      Strike.StrikeSlope 0
  | otherwise =
      Strike.StrikeSlope 1

cashSecuredPut
  :: Strike.StrikeX96
  -> Payoff.Payoff
cashSecuredPut strikePrice =
  Payoff.Payoff (`payoff` strikePrice)

plotPayoff
  :: FilePath
  -> SqrtPlot
  -> Strike.StrikeX96
  -> Strike.StrikeVariation
  -> IO ()
plotPayoff path config strikePrice variation =
  let
    originalPayoff = cashSecuredPut strikePrice
    variedStrike   = Strike.applyStrikeVariation strikePrice variation
    variedPayoff   = cashSecuredPut variedStrike
  in
    plotSqrtFunction
      path
      config
      [ Payoff.runPayoff originalPayoff
      , Payoff.runPayoff variedPayoff
      ]
