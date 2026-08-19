{-# LANGUAGE PatternSynonyms #-}

module Volatility.VolatilityGrid
  ( gammaCoordinate
  ) where

import Pricing.PriceDeformation (EtaX96(..))
import SqrtGrid
  ( Tick
  , TickSpacing
  , integerSqrt
  , invX96
  , pattern Q96
  , rpowX96
  , unTickSpacing
  )

-- Γ_φ(i) = ξ^{-3η(i+Δ_i/2)} as a Q96 word (ξ^0 = Q96).
-- ξ is the Q96 integer (unXiX96), not the XiX96 wrapper (avoids import cycle).
gammaCoordinate
  :: Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> Integer
gammaCoordinate xiWord (EtaX96 etaX96) spacing i =
  let
    d = toInteger (unTickSpacing spacing)
    num = 3 * etaX96 * (2 * toInteger i + d)
    den = 2 * Q96
    g = gcd num den
    nPowI = num `div` g
    nPow = fromInteger (abs nPowI) :: Int
    nRoot = den `div` g
    inv = invX96 xiWord
    base = if nPowI >= 0 then inv else xiWord
    powered = rpowX96 base nPow
  in
    applySqrts nRoot powered

applySqrts :: Integer -> Integer -> Integer
applySqrts 1 w = w
applySqrts m w
  | m > 1 && even m =
      applySqrts (m `div` 2) (integerSqrt (w * Q96))
  | otherwise =
      error "Volatility.VolatilityGrid.gammaCoordinate: exponent denominator is not a power of 2"
