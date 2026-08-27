module Payoffs.VolatilityCall
  ( VolStrike
  , mkVolStrike
  , unVolStrike
  , payoff
  , volatilityCall
  ) where

import Volatility.TickVolatility
  ( RangeVolatility(..)
  )

newtype VolStrike = VolStrike Integer
  deriving (Show, Eq)

mkVolStrike :: Integer -> VolStrike
mkVolStrike k
  | k < 0 =
      error "Payoffs.VolatilityCall.mkVolStrike: K must be >= 0"
  | otherwise = VolStrike k

unVolStrike :: VolStrike -> Integer
unVolStrike (VolStrike k) = k

payoff :: RangeVolatility -> VolStrike -> RangeVolatility
payoff (RangeVolatility s) (VolStrike k) =
  RangeVolatility (max (s - k) 0)

volatilityCall :: VolStrike -> (RangeVolatility -> RangeVolatility)
volatilityCall k s = payoff s k

