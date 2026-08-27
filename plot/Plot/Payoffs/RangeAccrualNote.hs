-- | Chart layouts for 'Payoffs.RangeAccrualNote'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.RangeAccrualNote
  ( plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  )
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction)
import StrikeX96 (StrikeX96(..))
import OptionRatio (OptionRatio(..))
import Payoffs.RangeAccrualNote


plotPayoff :: FilePath -> SqrtPlot -> StrikeX96 -> OptionRatio -> IO ()
plotPayoff path config k r =
  plotSqrtFunction path config PayoffY [Payoff.runPayoff (rangeAccrualNote k r)]

-- Lower boundary: kappa / sqrt(r)  in X96
lowerBound :: StrikeX96 -> OptionRatio -> Integer
lowerBound (StrikeX96 k) (OptionRatio r) =
  floor (fromInteger k / sqrt r)

-- Upper boundary: kappa * sqrt(r)  in X96
upperBound :: StrikeX96 -> OptionRatio -> Integer
upperBound (StrikeX96 k) (OptionRatio r) =
  floor (fromInteger k * sqrt r)

-- 2*p*k*sqrt(r) - p^2*r - k^2  (lower arm numerator), result in X96
lowerArmNumerator :: Integer -> Integer -> Double -> Integer
lowerArmNumerator p k r =
  let sqrtR = sqrt r
      term1 = 2 * fromInteger (p * k `div` q96) * sqrtR
      term2 = fromInteger (p * p `div` q96) * r
      term3 = fromInteger (k * k `div` q96)
  in  floor (term1 - term2 - term3)
  where q96 = 79228162514264337593543950336

-- 2*p*k*sqrt(r) - p^2 - k^2*r  (upper arm numerator), result in X96
upperArmNumerator :: Integer -> Integer -> Double -> Integer
upperArmNumerator p k r =
  let sqrtR = sqrt r
      term1 = 2 * fromInteger (p * k `div` q96) * sqrtR
      term2 = fromInteger (p * p `div` q96)
      term3 = fromInteger (k * k `div` q96) * r
  in  floor (term1 - term2 - term3)
  where q96 = 79228162514264337593543950336
