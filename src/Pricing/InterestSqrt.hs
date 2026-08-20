{-# LANGUAGE PatternSynonyms #-}

module Pricing.InterestSqrt
  ( InterestTick(..)
  , mkInterestTick
  , unInterestTick
  , InterestSqrtX96(..)
  , unInterestSqrtX96
  , interestSqrtX96
  ) where

import SqrtGrid (pattern Q96, tickBase)

-- | Time-step index for the interest lattice. Not a price 'Tick'.
newtype InterestTick = InterestTick Int
  deriving (Show, Eq, Ord)

mkInterestTick :: Int -> InterestTick
mkInterestTick = InterestTick

unInterestTick :: InterestTick -> Int
unInterestTick (InterestTick t) = t

-- | \(\sqrt{1+r}\) in Q96 with \(1+r=\lambda^{t}\). Dimensional twin of
-- 'SqrtPriceX96'; do not mix with price √.
newtype InterestSqrtX96 = InterestSqrtX96 Integer
  deriving (Show, Eq, Ord)

unInterestSqrtX96 :: InterestSqrtX96 -> Integer
unInterestSqrtX96 (InterestSqrtX96 s) = s

-- | Twin of 'SqrtGrid.sqrtPriceX96': \(s_r=\lambda^{t/2}\).
interestSqrtX96 :: InterestTick -> InterestSqrtX96
interestSqrtX96 (InterestTick t) =
  InterestSqrtX96 $
    floor $ tickBase ** (fromIntegral t / 2) * fromIntegral Q96
