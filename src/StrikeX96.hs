{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}

module StrikeX96
  ( StrikeX96(..)
  , Strike
  , strike
  , StrikeSlope(..)
  , StrikeVariation(..)
  , applyStrikeVariation
  ) where

import SqrtGrid (SqrtPriceX96(..))
import OptionRatio (OptionRatio(..))

newtype StrikeX96 =
  StrikeX96 Integer
  deriving (Show, Eq, Ord)

class Strike a b where
  strike :: a -> b -> StrikeX96

instance Strike SqrtPriceX96 SqrtPriceX96 where
  strike (SqrtPriceX96 pa) (SqrtPriceX96 pb) =
    StrikeX96 $
      floor $
        sqrt (fromIntegral pa * fromIntegral pb :: Double)

instance Strike SqrtPriceX96 OptionRatio where
  strike (SqrtPriceX96 pa) (OptionRatio r) =
    StrikeX96 $
      floor $
        fromIntegral pa * sqrt r


-- ∂π / ∂K
-- Dimensionless.
newtype StrikeSlope =
  StrikeSlope Rational
  deriving (Show, Eq, Ord)


-- ΔK in X96 strike coordinates.
data StrikeVariation =
  StrikeVariation
    { strikeDelta :: Integer
    }
  deriving (Show, Eq, Ord)

applyStrikeVariation
  :: StrikeX96
  -> StrikeVariation
  -> StrikeX96


applyStrikeVariation (StrikeX96 strikePrice) (StrikeVariation deltaK) = StrikeX96 (strikePrice + deltaK)

