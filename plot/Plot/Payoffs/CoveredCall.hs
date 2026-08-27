-- | Chart layouts for 'Payoffs.CoveredCall'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.CoveredCall
  ( plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff
import qualified StrikeX96 as Strike
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  )
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction)
import Payoffs.CoveredCall


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
