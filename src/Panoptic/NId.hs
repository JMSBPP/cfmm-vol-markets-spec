module Panoptic.NId
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
  , panopticAsset
  , panopticTokenType
  , panopticStrike
  , panopticWidth
  , volOrderToMintPlan
  , volOrderToTokenId
  ) where

import Data.Bits (shiftL, shiftR, (.&.))
import Liquidity.LiquidityChunk (createChunk)
import Panoptic.MintPlan (MintPlan(..), PanopticTokenId(..), fourLegNumLegs)
import TargetVega (mkTargetVega, unTargetVega)
import Pricing.PriceDeformation (uniswapMaxTick, uniswapMinTick)
import SqrtGrid (unTickSpacing)
import Volatility.VolOrder
  ( VolOrder
  , fixtureSymmetricVolOrder
  , legIntervals
  , tickBucketFromVolOrder
  , volTargetVega
  )

-- Hop A: optional-space scale N_id = 2/N. Not a Panoptic field.

newtype NId = NId Int
  deriving (Show, Eq)

mkNId :: Int -> NId
mkNId n
  | n < 2 || odd n =
      error "Panoptic.NId.mkNId: N must be even and ≥ 2"
  | otherwise = NId n

unNId :: NId -> Int
unNId (NId n) = n

nSigma :: NId -> Integer
nSigma (NId n) = toInteger n `div` 2

scaleByNId :: NId -> Integer -> Integer
scaleByNId (NId n) x = (2 * x) `div` toInteger n

-- Hop B: EVM/Panoptic tokenId + SFPM positionSize. ΔQ_v* is not in the id.
-- Layout matches plank PanopticTokenId.plk (TokenId.sol offsets).
-- PanopticTokenId / MintPlan / fourLegNumLegs live in Panoptic.MintPlan
-- (split out so TargetVega, needed by Volatility.VolOrder's
-- targetVega field, does not import this module — avoids a
-- NId → VolOrder → TargetVega → NId cycle).

-- Geometry-derived 4-leg all-long position: puts on [i_l,i*), calls on
-- [i*,i_u]; the four leg intervals and Δ come from `VolOrder` (Layer 1),
-- not hardcoded ticks. Per-leg optionRatio is the caller 4-tuple (1..127),
-- not Kristensen OptionRatio and not quantized w_k.
volOrderToTokenId
  :: VolOrder
  -> Integer
  -> (Integer, Integer, Integer, Integer)
  -> PanopticTokenId
volOrderToTokenId vo poolId (r0, r1, r2, r3)
  | any (\r -> r < 1 || r > 127) [r0, r1, r2, r3] =
      error "Panoptic.NId.volOrderToTokenId: optionRatio must be in 1..127"
  | not (all spanFeasible intervals) =
      error "Panoptic.NId.volOrderToTokenId: each leg span must be >= tick spacing"
  | putSide < 2 * d || callSide < 2 * d =
      error "Panoptic.NId.volOrderToTokenId: each side of i* must be >= 2 * tick spacing"
  | not (all widthPackable intervals) =
      error "Panoptic.NId.volOrderToTokenId: each leg width must be < 4096 tick spacings (TokenId width field is 12 bits)"
  | not (all tickInPoolBounds allTicks) =
      error "Panoptic.NId.volOrderToTokenId: ticks must satisfy |tick| <= uniswapMaxTick"
  | otherwise =
      let
        tid0 = addLegFromBucket 0 l0 h0 d 0
        tid1 = addLegFromBucket tid0 l1 h1 d 1
        tid2 = addLegFromBucket tid1 l2 h2 d 2
        tid3 = addLegFromBucket tid2 l3 h3 d 3
        tid4 = addTokenType tid3 0 0
        tid5 = addTokenType tid4 0 1
        tid6 = addTokenType tid5 1 2
        tid7 = addTokenType tid6 1 3
        -- asset = 1 on every leg: single token1 basis for positionSize·optionRatio
        -- (PanopticMath.getLiquidityChunk: asset==1 → getLiquidityForAmount1). TODO #28 item 0.
        tidA = addAsset (addAsset (addAsset (addAsset tid7 1 0) 1 1) 1 2) 1 3
        tid8 = addIsLong tidA 1 0
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
        tid20 = addTickSpacing tid19 d
      in
        PanopticTokenId tid20 4
  where
    (_, _, ts) = tickBucketFromVolOrder vo
    d = toInteger (unTickSpacing ts)
    intervals =
      [ (toInteger lo, toInteger hi)
      | (lo, hi) <- legIntervals vo
      ]
    (l0, h0) = intervals !! 0
    (l1, h1) = intervals !! 1
    (l2, h2) = intervals !! 2
    (l3, h3) = intervals !! 3
    spanFeasible (lo, hi) = hi - lo >= d
    putSide = h1 - l0
    callSide = h3 - l2
    widthPackable (lo, hi) = (hi - lo) `div` d < maxPackedWidth
    allTicks = concat [[lo, hi] | (lo, hi) <- intervals]
    tickInPoolBounds t =
      t >= toInteger uniswapMinTick && t <= toInteger uniswapMaxTick

-- TokenId width field is 12 bits (mask 0xfff in addWidth) → widthInTicks < 2^12.
maxPackedWidth :: Integer
maxPackedWidth = 4096

-- MintPlan: tokenId from geometry + ratios, chunk = envelope [i_l, i_u] at
-- liquidity ΔQ_v* (VolOrder's targetVega field, M1 shape).
volOrderToMintPlan
  :: VolOrder
  -> Integer
  -> (Integer, Integer, Integer, Integer)
  -> MintPlan
volOrderToMintPlan vo poolId ratios =
  let
    tid = volOrderToTokenId vo poolId ratios
    (iL, iU, _) = tickBucketFromVolOrder vo
    ch = createChunk iL iU (unTargetVega (volTargetVega vo))
  in
    MintPlan tid ch

-- Thin wrapper: fixture VolOrder (vega irrelevant — tokenId is scale-free,
-- size comes from MintPlan) reproduces the legacy fixed-tick skeleton.
fourLegSkeleton :: Integer -> (Integer, Integer, Integer, Integer) -> PanopticTokenId
fourLegSkeleton poolId ratios =
  volOrderToTokenId (fixtureSymmetricVolOrder (mkTargetVega 1)) poolId ratios

panopticTickSpacing :: PanopticTokenId -> Integer
panopticTickSpacing (PanopticTokenId tid _) =
  shiftR tid 48 .&. 0xffff

panopticOptionRatio :: PanopticTokenId -> Integer -> Integer
panopticOptionRatio tid leg =
  shiftR (tokenId tid) (legBase leg + 1) .&. 0x7f

-- | asset bit: TokenId bit 64 + 48·leg (TokenId.sol `asset`).
panopticAsset :: PanopticTokenId -> Integer -> Integer
panopticAsset tid leg =
  shiftR (tokenId tid) (legBase leg) .&. 0x1

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

addAsset :: Integer -> Integer -> Integer -> Integer
addAsset tid v leg =
  addField tid (legBase leg) 0x1 v

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
    tickSpan = hi - lo
    strike = lo + tickSpan `div` 2
    width = tickSpan `div` ts
  in
    addWidth (addStrike tid strike leg) width leg

signExtend24 :: Integer -> Integer
signExtend24 w =
  if w >= 0x800000 then w - 0x1000000 else w
