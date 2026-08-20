-- | Bunni `liquidityDensityX96` surface (re-export).
--
-- TODO (brainstorm): map LiquidityDensity → LiquidityChunk and/or → Panoptic
-- 7-bit optionRatio (\(r_k \propto \ell_k \cdot \mathrm{dsqrt}_k\), quantize 1..127).
-- Open design:
--   docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md
-- Do not implement that map here until the brainstorm is approved as a follow-up.
-- Not Kristensen 'OptionRatio' (bound-setting r in OptionRatio.hs).
--
-- TODO: TickLiquidity + kappaAt(chunk) live in TickLiquidity.hs / KappaCoordinate.hs
-- (geometric L this cycle). Chunk×density EVM mul (Bunni/Panoptic) still open —
-- do not implement that mul here until brainstormed.
module Liquidity.LiquidityDensity
  ( LiquidityDensityX96(..)
  , unLiquidityDensityX96
  , liquidityDensityToDouble
  ) where

import Liquidity.LiquidityGrid
  ( LiquidityDensityX96(..)
  , liquidityDensityToDouble
  , unLiquidityDensityX96
  )
