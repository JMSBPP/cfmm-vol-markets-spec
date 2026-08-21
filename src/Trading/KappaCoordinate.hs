{-# LANGUAGE PatternSynonyms #-}

module Trading.KappaCoordinate
  ( KappaTick(..)
  , mkKappaTick
  , unKappaTick
  , KappaSpacing(..)
  , mkKappaSpacing
  , defaultKappaSpacing
  , unKappaSpacing
  , kappaFromTick
  , snapKappaTick
  , KappaCoordinate(..)
  , kappaAt
  ) where

import Data.Maybe (fromMaybe)

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
-- VISIBLE NOTE — κ encoding C (do not bury / do not delete)
--
-- THIS CYCLE (C): KappaTick = discrete rung index j on uniform lattice
--   κ_j = j/N over [0,1], N = 255 (defaultKappaSpacing).
--   Snap: round(κ_real * N) clipped to 0..N. On-chain uint8 = index, not
--   a compressed-float costume.
--
-- B RETIRED: KappaPips / quantizeKappaPips (Word8 of real κ) removed.
--
-- Def 45 unchanged: high-res κ_real, then snapKappaTick.
-- Deferred: π^φ(r_φ^e), ExpectedReturn <> Realized (future r(0)).
-- r(κ; φ_X, φ_M) / κ·φ shipped in Pricing.ExpectedReturn.
-- Also mirrored in scratchpad/README.md and the C design spec.
-- ---------------------------------------------------------------------------

newtype KappaSpacing = KappaSpacing Int
  deriving (Show, Eq, Ord)

mkKappaSpacing :: Int -> KappaSpacing
mkKappaSpacing n
  | n /= 255 =
      error "Trading.KappaCoordinate.mkKappaSpacing: only N=255 this cycle"
  | otherwise = KappaSpacing n

defaultKappaSpacing :: KappaSpacing
defaultKappaSpacing = KappaSpacing 255

unKappaSpacing :: KappaSpacing -> Int
unKappaSpacing (KappaSpacing n) = n

newtype KappaTick = KappaTick Int
  deriving (Show, Eq, Ord)

mkKappaTick :: KappaSpacing -> Integer -> KappaTick
mkKappaTick (KappaSpacing n) j
  | j < 0 || j > fromIntegral n =
      error "Trading.KappaCoordinate.mkKappaTick: KappaTick must be in 0..N"
  | otherwise = KappaTick (fromIntegral j)

unKappaTick :: KappaTick -> Int
unKappaTick (KappaTick j) = j

kappaFromTick :: KappaSpacing -> KappaTick -> Double
kappaFromTick (KappaSpacing n) (KappaTick j) =
  fromIntegral j / fromIntegral n

snapKappaTick :: KappaSpacing -> Double -> KappaTick
snapKappaTick sp@(KappaSpacing n) k =
  let
    j = round (k * fromIntegral n) :: Integer
  in
    mkKappaTick sp (max 0 (min (fromIntegral n) j))

newtype KappaCoordinate = KappaCoordinate KappaTick
  deriving (Show, Eq)

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
    KappaCoordinate (snapKappaTick defaultKappaSpacing kappaReal)
