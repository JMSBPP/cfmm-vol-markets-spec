module Payoffs.NId
  ( NId
  , mkNId
  , unNId
  , nSigma
  , scaleByNId
  , PanopticTokenId(..)
  , MintPlan(..)
  , fourLegSkeleton
  , fourLegNumLegs
  , panopticTickSpacing
  , panopticOptionRatio
  , panopticIsLong
  , panopticTokenType
  , panopticStrike
  , panopticWidth
  ) where

import Data.Bits (shiftL, shiftR, (.&.))

-- Hop A: optional-space scale N_id = 2/N. Not a Panoptic field.

newtype NId = NId Int
  deriving (Show, Eq)

mkNId :: Int -> NId
mkNId n
  | n < 2 || odd n =
      error "Payoffs.NId.mkNId: N must be even and ≥ 2"
  | otherwise = NId n

unNId :: NId -> Int
unNId (NId n) = n

nSigma :: NId -> Integer
nSigma (NId n) = toInteger n `div` 2

scaleByNId :: NId -> Integer -> Integer
scaleByNId (NId n) x = (2 * x) `div` toInteger n

-- Hop B: EVM/Panoptic tokenId + SFPM positionSize. ΔQ_v* is not in the id.
-- Layout matches plank PanopticTokenId.plk (TokenId.sol offsets).

data PanopticTokenId = PanopticTokenId
  { tokenId :: Integer
  , numLegs :: Integer
  }
  deriving (Show, Eq)

data MintPlan = MintPlan
  { mintTokenId      :: PanopticTokenId
  , mintPositionSize :: Integer
  }
  deriving (Show, Eq)

fourLegNumLegs :: PanopticTokenId -> Int
fourLegNumLegs tid = fromInteger (numLegs tid)

-- Canonical 4-leg all-long skeleton around i*=0, Δ=10:
-- puts [-20,-10], [-10,0] | calls [0,10], [10,20]. Per-leg optionRatio is the
-- caller 4-tuple (1..127), not Kristensen OptionRatio and not quantized w_k.
fourLegSkeleton :: Integer -> (Integer, Integer, Integer, Integer) -> PanopticTokenId
fourLegSkeleton poolId (r0, r1, r2, r3)
  | any (\r -> r < 1 || r > 127) [r0, r1, r2, r3] =
      error "Payoffs.NId.fourLegSkeleton: optionRatio must be in 1..127"
  | otherwise =
      let
        ts = 10
        tid0 = addLegFromBucket 0 (-20) (-10) ts 0
        tid1 = addLegFromBucket tid0 (-10) 0 ts 1
        tid2 = addLegFromBucket tid1 0 10 ts 2
        tid3 = addLegFromBucket tid2 10 20 ts 3
        tid4 = addTokenType tid3 0 0
        tid5 = addTokenType tid4 0 1
        tid6 = addTokenType tid5 1 2
        tid7 = addTokenType tid6 1 3
        tid8 = addIsLong tid7 1 0
        tid9 = addIsLong tid8 1 1
        tid10 = addIsLong tid9 1 2
        tid11 = addIsLong tid10 1 3
        tid12 = addOptionRatio tid11 r0 0
        tid13 = addOptionRatio tid12 r1 1
        tid14 = addOptionRatio tid13 r2 2
        tid15 = addOptionRatio tid14 r3 3
        tid16 = addRiskPartner tid15 1 1
        tid17 = addRiskPartner tid16 2 2
        tid18 = addRiskPartner tid17 3 3
        tid19 = addPoolId tid18 (poolId .&. 0xffffffffffff)
        tid20 = addTickSpacing tid19 ts
      in
        PanopticTokenId tid20 4

panopticTickSpacing :: PanopticTokenId -> Integer
panopticTickSpacing (PanopticTokenId tid _) =
  shiftR tid 48 .&. 0xffff

panopticOptionRatio :: PanopticTokenId -> Integer -> Integer
panopticOptionRatio tid leg =
  shiftR (tokenId tid) (legBase leg + 1) .&. 0x7f

panopticIsLong :: PanopticTokenId -> Integer -> Integer
panopticIsLong tid leg =
  shiftR (tokenId tid) (legBase leg + 8) .&. 0x1

panopticTokenType :: PanopticTokenId -> Integer -> Integer
panopticTokenType tid leg =
  shiftR (tokenId tid) (legBase leg + 9) .&. 0x1

panopticStrike :: PanopticTokenId -> Integer -> Integer
panopticStrike tid leg =
  signExtend24 (shiftR (tokenId tid) (legBase leg + 12) .&. 0xffffff)

panopticWidth :: PanopticTokenId -> Integer -> Integer
panopticWidth tid leg =
  shiftR (tokenId tid) (legBase leg + 36) .&. 0xfff

legBase :: Integer -> Int
legBase leg = 64 + 48 * fromInteger leg

addField :: Integer -> Int -> Integer -> Integer -> Integer
addField tid bitOff mask val =
  tid + shiftL (val .&. mask) bitOff

addPoolId :: Integer -> Integer -> Integer
addPoolId tid poolId = addField tid 0 0xffffffffffffffff poolId

addTickSpacing :: Integer -> Integer -> Integer
addTickSpacing tid ts = addField tid 48 0xffff ts

addOptionRatio :: Integer -> Integer -> Integer -> Integer
addOptionRatio tid v leg =
  addField tid (legBase leg + 1) 0x7f v

addIsLong :: Integer -> Integer -> Integer -> Integer
addIsLong tid v leg =
  addField tid (legBase leg + 8) 0x1 v

addTokenType :: Integer -> Integer -> Integer -> Integer
addTokenType tid v leg =
  addField tid (legBase leg + 9) 0x1 v

addRiskPartner :: Integer -> Integer -> Integer -> Integer
addRiskPartner tid v leg =
  addField tid (legBase leg + 10) 0x3 v

addStrike :: Integer -> Integer -> Integer -> Integer
addStrike tid strike leg =
  addField tid (legBase leg + 12) 0xffffff (strike .&. 0xffffff)

addWidth :: Integer -> Integer -> Integer -> Integer
addWidth tid width leg =
  addField tid (legBase leg + 36) 0xfff width

addLegFromBucket :: Integer -> Integer -> Integer -> Integer -> Integer -> Integer
addLegFromBucket tid lo hi ts leg =
  let
    span = hi - lo
    strike = lo + span `div` 2
    width = span `div` ts
  in
    addWidth (addStrike tid strike leg) width leg

signExtend24 :: Integer -> Integer
signExtend24 w =
  if w >= 0x800000 then w - 0x1000000 else w
