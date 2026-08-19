{-# LANGUAGE PatternSynonyms #-}

module State
  ( pattern SQRT_PRICE_1_4
  , pattern SQRT_PRICE_4_1
  ) where

import SqrtGrid (SqrtPriceX96(..))

pattern SQRT_PRICE_1_4 :: SqrtPriceX96
pattern SQRT_PRICE_1_4 =
  SqrtPriceX96 39614081257132168796771975168

pattern SQRT_PRICE_4_1 :: SqrtPriceX96
pattern SQRT_PRICE_4_1 =
  SqrtPriceX96 158456325028528675187087900672