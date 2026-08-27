{-# LANGUAGE PatternSynonyms #-}

module Pricing.PriceDeformation
  ( EtaX96(..)
  , VarSigmaX96(..)
  , pattern BASE_ETA
  , barSqrtPriceX96
  , uniswapMinTick
  , uniswapMaxTick
  , varSigma
  , deformTick
  , deformedSqrtPriceX96
  ) where

import SqrtGrid
  ( Tick
  , SqrtPriceX96(..)
  , pattern Q96
  , sqrtPriceX96
  )

-- η · 2^96, with 0 < η < 1
newtype EtaX96 = EtaX96 Integer
  deriving (Show, Eq, Ord)

-- ς · 2^96, ς = η/(1-η) > 0
newtype VarSigmaX96 = VarSigmaX96 Integer
  deriving (Show, Eq, Ord)

-- Uniswap CPMM: η = 1/2, stored as 2^95
pattern BASE_ETA :: EtaX96
pattern BASE_ETA = EtaX96 39614081257132168796771975168

-- Tick 0: sqrt(P) = 1 in Q96
barSqrtPriceX96 :: SqrtPriceX96
barSqrtPriceX96 = SqrtPriceX96 Q96

uniswapMinTick :: Tick
uniswapMinTick = -887272

uniswapMaxTick :: Tick
uniswapMaxTick = 887272

-- ς_X96 = η_X96 * Q96 / (Q96 - η_X96)
varSigma :: EtaX96 -> VarSigmaX96
varSigma (EtaX96 eta)
  | eta <= 0 || eta >= Q96 =
      error "PriceDeformation.varSigma: η must satisfy 0 < η < 1"
  | otherwise =
      VarSigmaX96 $ (eta * Q96) `div` (Q96 - eta)

-- i' = floor(i * ς / 2^96); Nothing if i' is not a v3 tick
deformTick :: EtaX96 -> Tick -> Maybe Tick
deformTick eta i =
  let
    VarSigmaX96 varsigma = varSigma eta
    deformed =
      fromInteger $
        (toInteger i * varsigma) `div` Q96
  in
    if deformed < uniswapMinTick || deformed > uniswapMaxTick
      then Nothing
      else Just deformed

deformedSqrtPriceX96 :: EtaX96 -> Tick -> Maybe SqrtPriceX96
deformedSqrtPriceX96 eta i =
  sqrtPriceX96 <$> deformTick eta i
