{-# LANGUAGE PatternSynonyms #-}

module Trading.KappaCoordinate
  ( KappaPips(..)
  , mkKappaPips
  , unKappaPips
  , KappaCoordinate(..)
  , kappaMax
  , quantizeKappaPips
  , kappaAt
  ) where

import Data.Maybe (fromMaybe)
import Data.Word (Word8)

import Liquidity.LiquidityChunk
  ( LiquidityChunk
  , chunkTickLower
  , chunkTickUpper
  )
import Liquidity.LiquidityGrid (XiX96)
import Liquidity.TickLiquidity (TickLiquidity(..), tickLiquidityAt)
import Pricing.PriceDeformation (EtaX96(..), pattern BASE_ETA)
import SqrtGrid (pattern Q96)

-- ---------------------------------------------------------------------------
-- VISIBLE NOTE — κ encoding upgrade (do not bury / do not delete)
--
-- THIS CYCLE (B): KappaPips = 8-bit quantization of a real κ on [0, κ_max].
--   κ_max = 1; pips = round(κ / κ_max * 255) clipped to 0..255.
--
-- UPGRADE PATH (C): discrete κ *rung index* (tick analogue) — stable discrete
--   identity, composable for later r(κ; φ_X, φ_M) / fee-tree walks; on-chain
--   uint8 as index, not a compressed float costume.
--
-- When κ becomes a first-class atlas axis next to λ / ξ, promote B → C.
-- Keep Def 45 high-res compute, then snap to a rung.
-- Also mirrored in scratchpad/README.md and the Def 45 design spec.
-- ---------------------------------------------------------------------------

newtype KappaPips = KappaPips Word8
  deriving (Show, Eq, Ord)

mkKappaPips :: Integer -> KappaPips
mkKappaPips p
  | p < 0 || p > 255 =
      error "Trading.KappaCoordinate.mkKappaPips: KappaPips must be in 0..255"
  | otherwise = KappaPips (fromIntegral p)

unKappaPips :: KappaPips -> Word8
unKappaPips (KappaPips w) = w

newtype KappaCoordinate = KappaCoordinate KappaPips
  deriving (Show, Eq)

-- Spec pin: cover geometric trading bases for Δ ≥ 1 at η = 1/2.
kappaMax :: Double
kappaMax = 1

quantizeKappaPips :: Double -> KappaPips
quantizeKappaPips k =
  let
    x = round (k / kappaMax * 255) :: Integer
  in
    mkKappaPips (max 0 (min 255 x))

etaToDouble :: EtaX96 -> Double
etaToDouble (EtaX96 e) = fromIntegral e / fromIntegral Q96

-- Def 45 / Thm 43(iii): geometric book ⇒ trading base κ = 1/(2ηΔ).
-- Evaluate TickLiquidity at chunk bounds (L>0 path); closed form avoids
-- Double logBase noise and mulX96 truncation on small L.
kappaAt :: Maybe EtaX96 -> XiX96 -> LiquidityChunk -> KappaCoordinate
kappaAt mEta xi ch =
  let
    eta = fromMaybe BASE_ETA mEta
    lo = chunkTickLower ch
    hi = chunkTickUpper ch
    delta = hi - lo
    TickLiquidity _ lLo = tickLiquidityAt xi ch lo
    TickLiquidity _ lHi = tickLiquidityAt xi ch hi
    etaR = etaToDouble eta
    kappaReal =
      if lLo <= 0 || lHi <= 0 || delta <= 0 || etaR <= 0
        then error "Trading.KappaCoordinate.kappaAt: invalid L, Δ, or η"
        else 1 / (2 * etaR * fromIntegral delta)
  in
    KappaCoordinate (quantizeKappaPips kappaReal)
