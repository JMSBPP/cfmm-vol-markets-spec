module Volatility.TickVolatility
  ( volatilityOnRange
  , VolatilityAverage(..)
  , unVolatilityAverage
  , averageVolatility
  , RangeVolatility(..)
  , unRangeVolatility
  , rangeAlongPath
  ) where

import qualified Data.Vector as V
import TickPath (TickPath(..))

-- Integer window mean of _volatilityOnRange. Not Double, not Q96, not Algebra uint88.
newtype VolatilityAverage = VolatilityAverage Integer
  deriving (Show, Eq)

unVolatilityAverage :: VolatilityAverage -> Integer
unVolatilityAverage (VolatilityAverage x) = x

-- One Algebra _volatilityOnRange word (a segment, not the window mean).
newtype RangeVolatility = RangeVolatility Integer
  deriving (Show, Eq)

unRangeVolatility :: RangeVolatility -> Integer
unRangeVolatility (RangeVolatility x) = x

-- Algebra VolatilityOracle._volatilityOnRange (dt>0). Same integer `div`; unbounded, not uint88.
volatilityOnRange
  :: Integer
  -> Integer
  -> Integer
  -> Integer
  -> Integer
  -> Integer
volatilityOnRange dt tick0 tick1 avg0 avg1
  | dt <= 0 =
      error "Volatility.TickVolatility.volatilityOnRange: dt must be > 0"
  | otherwise =
      let
        k = (tick1 - tick0) - (avg1 - avg0)
        b = (tick0 - avg0) * dt
        sumOfSequence = dt * (dt + 1)
        sumOfSquares = sumOfSequence * (2 * dt + 1)
      in
        (k * k * sumOfSquares + 6 * b * k * sumOfSequence + 6 * dt * b * b)
          `div` (6 * dt * dt)

rangeAlongPath :: TickPath -> V.Vector RangeVolatility
rangeAlongPath path =
  let
    n = pathLength path
    ts = ticks path
    avgs = prefixMeans ts
    dt = 1 :: Integer
  in
    V.generate (n - 1) $ \j ->
      RangeVolatility $
        volatilityOnRange
          dt
          (toInteger (ts V.! j))
          (toInteger (ts V.! (j + 1)))
          (avgs V.! j)
          (avgs V.! (j + 1))

averageVolatility :: TickPath -> VolatilityAverage
averageVolatility path =
  let
    rs = rangeAlongPath path
    total = V.sum (V.map unRangeVolatility rs)
  in
    VolatilityAverage (total `div` toInteger (V.length rs))

prefixMeans :: V.Vector Int -> V.Vector Integer
prefixMeans ts =
  let
    n = V.length ts
    running = V.scanl' (+) 0 (V.map toInteger ts)
  in
    V.generate n $ \j -> running V.! (j + 1) `div` toInteger (j + 1)
