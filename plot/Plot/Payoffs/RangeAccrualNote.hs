-- | Chart layouts for 'Payoffs.RangeAccrualNote'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.RangeAccrualNote
  ( plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff
import SqrtGrid
  ( SqrtPlot
  )
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction)
import StrikeX96 (StrikeX96(..))
import OptionRatio (OptionRatio(..))
import Payoffs.RangeAccrualNote

plotPayoff :: FilePath -> SqrtPlot -> StrikeX96 -> OptionRatio -> IO ()
plotPayoff path config k r =
  plotSqrtFunction path config PayoffY [Payoff.runPayoff (rangeAccrualNote k r)]
