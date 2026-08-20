module Pricing.InterestPriceMap
  ( InterestPriceMap(..)
  , mkInterestPriceMap
  , priceTickAt
  ) where

import Pricing.InterestSqrt (InterestTick, unInterestTick)
import SqrtGrid (Tick)

-- | Affine link \(i(t)=k\cdot t+i_0\) between interest tenor and price tick.
data InterestPriceMap = InterestPriceMap
  { ipmK  :: Int
  , ipmI0 :: Tick
  }
  deriving (Show, Eq)

mkInterestPriceMap :: Int -> Tick -> InterestPriceMap
mkInterestPriceMap k i0
  | k <= 0 =
      error "Pricing.InterestPriceMap.mkInterestPriceMap: k must be > 0"
  | otherwise = InterestPriceMap k i0

priceTickAt :: InterestPriceMap -> InterestTick -> Tick
priceTickAt (InterestPriceMap k i0) t =
  i0 + k * unInterestTick t
