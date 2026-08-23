module Volatility.ImpliedVolatility
  ( ImpliedVolatility(..)
  , unImpliedVolatility
  , impliedVolatilityFromAverage
  ) where

import Volatility.TickVolatility (VolatilityAverage(..))

-- | Kristensen σ_IV word (full u-map in TODO #20).
newtype ImpliedVolatility = ImpliedVolatility Integer
  deriving (Show, Eq)

unImpliedVolatility :: ImpliedVolatility -> Integer
unImpliedVolatility (ImpliedVolatility x) = x

-- Slice 1 stand-in until uStarFromCalibration lands.
impliedVolatilityFromAverage :: VolatilityAverage -> ImpliedVolatility
impliedVolatilityFromAverage (VolatilityAverage x) = ImpliedVolatility x
