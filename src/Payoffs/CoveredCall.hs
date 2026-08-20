module Payoffs.CoveredCall
  ( payoff
  , coveredCall
  , strikeDerivative
  , plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff
import qualified StrikeX96 as Strike

import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  )
import Payoffs.PlotSqrt (PlotY(..), plotSqrtFunction)


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
        p - max (p - k) 0


coveredCall
  :: Strike.StrikeX96
 -> Payoff.Payoff SqrtPriceX96
coveredCall strikePrice =
  Payoff.Payoff (`payoff` strikePrice)


strikeDerivative
  :: Strike.StrikeX96
  -> SqrtPriceX96
  -> Strike.StrikeSlope
strikeDerivative
  (Strike.StrikeX96 strikePrice)
  sqrtPrice
  | Payoff.squareSqrtPrice sqrtPrice
      > Payoff.squareSqrtPrice (SqrtPriceX96 strikePrice) =
      Strike.StrikeSlope 1
  | otherwise =
      Strike.StrikeSlope 0


plotPayoff
  :: FilePath
  -> SqrtPlot
  -> Strike.StrikeX96
  -> Strike.StrikeVariation
  -> IO ()
plotPayoff path config strikePrice variation =
  let
    originalPayoff =
      coveredCall strikePrice

    variedStrike =
      Strike.applyStrikeVariation
        strikePrice
        variation

    variedPayoff =
      coveredCall variedStrike

  in
    plotSqrtFunction
      path
      config
      PayoffY
      [ Payoff.runPayoff originalPayoff
      , Payoff.runPayoff variedPayoff
      ]