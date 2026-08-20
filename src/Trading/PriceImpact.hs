{-# LANGUAGE PatternSynonyms #-}

module Trading.PriceImpact
  ( PriceImpact(..)
  , askSqrtPriceX96
  , bidSqrtPriceX96
  ) where

import Pricing.Stremia
  ( FeePips
  , feeFactor
  , sqrtFeeFactorX96
  )
import SqrtGrid
  ( SqrtPriceX96(..)
  , invX96
  , mulX96
  )

newtype PriceImpact = PriceImpact Rational
  deriving (Show, Eq)

askSqrtPriceX96 :: FeePips -> SqrtPriceX96 -> SqrtPriceX96
askSqrtPriceX96 φ (SqrtPriceX96 s) =
  let sf = sqrtFeeFactorX96 (feeFactor φ)
  in  SqrtPriceX96 (mulX96 s sf)

bidSqrtPriceX96 :: FeePips -> SqrtPriceX96 -> SqrtPriceX96
bidSqrtPriceX96 φ (SqrtPriceX96 s) =
  let sf = sqrtFeeFactorX96 (feeFactor φ)
  in  SqrtPriceX96 (mulX96 s (invX96 sf))
