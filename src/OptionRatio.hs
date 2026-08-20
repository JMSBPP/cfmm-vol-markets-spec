module OptionRatio ( OptionRatio(..)) where

-- TODO (brainstorm): Kristensen bound-setting r is NOT Panoptic 7-bit optionRatio.
-- Mapping LiquidityDensity → Panoptic optionRatio (and Density → LiquidityChunk) is
-- open — see docs/superpowers/specs/2026-08-20-liquiditydensity-optionratio-brainstorm.md
-- Do not conflate this type with TokenId per-leg ratios or Bunni ℓ.

newtype OptionRatio = OptionRatio Double deriving (Show, Eq, Ord)


