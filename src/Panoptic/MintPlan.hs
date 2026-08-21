module Panoptic.MintPlan
  ( PanopticTokenId(..)
  , MintPlan(..)
  , fourLegNumLegs
  ) where

import Liquidity.LiquidityChunk (LiquidityChunk)

-- EVM/Panoptic tokenId + SFPM positionSize. Split out of Panoptic.NId so that
-- TargetVega (needed by Volatility.VolOrder's targetVega field) can
-- depend on these shapes without creating a NId -> VolOrder -> TargetVega ->
-- NId module cycle now that NId consumes VolOrder directly.

data PanopticTokenId = PanopticTokenId
  { tokenId :: Integer
  , numLegs :: Integer
  }
  deriving (Show, Eq)

data MintPlan = MintPlan
  { mintTokenId :: PanopticTokenId
  , mintChunk   :: LiquidityChunk
  }
  deriving (Show, Eq)

fourLegNumLegs :: PanopticTokenId -> Int
fourLegNumLegs tid = fromInteger (numLegs tid)
