-- | Chart layouts for 'Payoffs.CashSecuredPut'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.CashSecuredPut
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
import Payoffs.CashSecuredPut


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
      PayoffY
      [ Payoff.runPayoff originalPayoff
      , Payoff.runPayoff variedPayoff
      ]
