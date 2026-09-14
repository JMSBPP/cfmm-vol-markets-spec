{-# LANGUAGE PackageImports #-}

module HevmSqrtGrid (TickMath (..)) where

import Hevm (Hevm, callGetSqrtPriceAtTick)
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96, Tick)

class TickMath m where
  getSqrtPriceAtTick :: Tick -> m SqrtPriceX96

instance TickMath Hevm where
  getSqrtPriceAtTick = callGetSqrtPriceAtTick
