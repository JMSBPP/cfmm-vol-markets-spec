{-# LANGUAGE PatternSynonyms #-}

module Liquidity.LiquidityGrid
  ( XiX96(..)
  , mkXiX96
  , unXiX96
  , xiStar
  , xiCoordinate
  , LadderResolution
  , mkLadderResolution
  , unLadderResolution
  , LiquidityDensityX96(..)
  , unLiquidityDensityX96
  , liquidityDensityToDouble
  , ell
  ) where

import SqrtGrid
  ( SqrtPriceX96(..)
  , TickSpacing
  , invX96
  , pattern Q96
  , rpowX96
  , sqrtPriceX96
  , unTickSpacing
  )

newtype XiX96 = XiX96 Integer
  deriving (Show, Eq, Ord)

mkXiX96 :: Integer -> XiX96
mkXiX96 x
  | x <= 0 || x == Q96 =
      error "Liquidity.LiquidityGrid.mkXiX96: ξ must satisfy 0 < ξ, ξ ≠ 1"
  | otherwise = XiX96 x

unXiX96 :: XiX96 -> Integer
unXiX96 (XiX96 x) = x

xiStar :: TickSpacing -> XiX96
xiStar spacing =
  let
    SqrtPriceX96 s = sqrtPriceX96 (unTickSpacing spacing)
  in
    mkXiX96 (invX96 s)

-- Rung x only. ξ^x in Q96 via mulX96. ξ^0 = Q96 (the 1-word).
xiCoordinate :: XiX96 -> Int -> XiX96
xiCoordinate xi x
  | x < 0 = error "Liquidity.LiquidityGrid.xiCoordinate: x must be ≥ 0"
  | otherwise =
      let
        raw = unXiX96 xi
        (base, invertBase) =
          if raw > Q96
            then (invX96 raw, True)
            else (raw, False)
        pow = rpowX96 base x
        coord = if invertBase then invX96 pow else pow
      in
        if coord <= 0
          then error "Liquidity.LiquidityGrid.xiCoordinate: overflow"
          else XiX96 coord

newtype LadderResolution = LadderResolution Int
  deriving (Show, Eq, Ord)

mkLadderResolution :: Int -> LadderResolution
mkLadderResolution n
  | n < 1 =
      error "Liquidity.LiquidityGrid.mkLadderResolution: ι must be ≥ 1"
  | otherwise = LadderResolution n

unLadderResolution :: LadderResolution -> Int
unLadderResolution (LadderResolution n) = n

-- Bunni ILiquidityDensityFunction.query:
--   uint256 liquidityDensityX96  -- density of the rounded tick, scaled by Q96
-- Range [0, Q96]; partition of unity in that word (LibGeometricDistribution).
--
-- TODO (brainstorm): LiquidityDensity → LiquidityChunk / LiquidityDensity → Panoptic
-- optionRatio (r_k ∝ ℓ_k · dsqrt_k, 7-bit quantize) is NOT implemented — see
-- docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md
-- This type stays Bunni Q96 mass; it is not Kristensen OptionRatio and not chunk L.
newtype LiquidityDensityX96 = LiquidityDensityX96 Integer
  deriving (Show, Eq, Ord)

unLiquidityDensityX96 :: LiquidityDensityX96 -> Integer
unLiquidityDensityX96 (LiquidityDensityX96 y) = y

-- EVM uint256 as Chart y, same job as payoffToDouble for PayoffX96.
liquidityDensityToDouble :: LiquidityDensityX96 -> Double
liquidityDensityToDouble (LiquidityDensityX96 y) = fromIntegral y

ell :: XiX96 -> LadderResolution -> Int -> LiquidityDensityX96
ell xi iota x =
  let
    n = unLadderResolution iota
    raw0 = unXiX96 xi
  in
    if x < 0 || x >= n
      then error "Liquidity.LiquidityGrid.ell: x must satisfy 0 ≤ x < ι"
      else
        let
          (raw, xUse) =
            if raw0 > Q96
              then (invX96 raw0, n - 1 - x)
              else (raw0, x)
          xiPowX = rpowX96 raw xUse
          xiPowN = rpowX96 raw n
          den = Q96 - xiPowN
        in
          if den == 0
            then error "Liquidity.LiquidityGrid.ell: ξ^ι = 1"
            else
              LiquidityDensityX96 $
                (xiPowX * (Q96 - raw)) `div` den

