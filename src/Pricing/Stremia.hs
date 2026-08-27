{-# LANGUAGE PatternSynonyms #-}

module Pricing.Stremia
  ( Stremia(..)
  , feePipsScale
  , FeePips(..)
  , mkFeePips
  , unFeePips
  , FeeFactorX96(..)
  , unFeeFactorX96
  , feeFactor
  , nakedAskQ96
  , nakedBidQ96
  , askPayoff
  , bidPayoff
  , sqrtFeeFactorX96
  , feePipsFromAsk
  , feePipsFromBid
  , feePipsFromBidAsk
  , compositeFeePips
  , defaultFeePipsGrid
  ) where

import qualified Payoffs.Payoff as Payoff
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , integerSqrt
  , invX96
  , mulX96
  , pattern Q96
  )

-- Stremia container (stub retained).
newtype Stremia = Stremia Integer
  deriving (Show, Eq)

-- Algebra: FeePips / feePipsScale = φ (100 ↦ 0.0001).
feePipsScale :: Integer
feePipsScale = 1000000

newtype FeePips = FeePips Integer
  deriving (Show, Eq, Ord)

mkFeePips :: Integer -> FeePips
mkFeePips p
  | p < 0 = error "Pricing.Stremia.mkFeePips: FeePips must be ≥ 0"
  | otherwise = FeePips p

unFeePips :: FeePips -> Integer
unFeePips (FeePips p) = p

newtype FeeFactorX96 = FeeFactorX96 Integer
  deriving (Show, Eq, Ord)

unFeeFactorX96 :: FeeFactorX96 -> Integer
unFeeFactorX96 (FeeFactorX96 f) = f

-- (1+φ)_X96 = Q96 + mulX96 p (Q96² / feePipsScale)
feeFactor :: FeePips -> FeeFactorX96
feeFactor (FeePips p) =
  FeeFactorX96 $
    Q96 + mulX96 p (Q96 * Q96 `div` feePipsScale)

-- √(1+φ)_X96 from (1+φ)_X96
sqrtFeeFactorX96 :: FeeFactorX96 -> Integer
sqrtFeeFactorX96 (FeeFactorX96 f) = integerSqrt (f * Q96)

nakedAskQ96 :: FeePips -> SqrtPriceX96 -> PayoffX96
nakedAskQ96 φ s =
  let
    PayoffX96 p = Payoff.squareSqrtPrice s
    FeeFactorX96 f = feeFactor φ
  in
    PayoffX96 (mulX96 p f)

nakedBidQ96 :: FeePips -> SqrtPriceX96 -> PayoffX96
nakedBidQ96 φ s =
  let
    PayoffX96 p = Payoff.squareSqrtPrice s
    FeeFactorX96 f = feeFactor φ
  in
    PayoffX96 (mulX96 p (invX96 f))

askPayoff :: FeePips -> Payoff.Payoff SqrtPriceX96
askPayoff φ = Payoff.Payoff (nakedAskQ96 φ)

bidPayoff :: FeePips -> Payoff.Payoff SqrtPriceX96
bidPayoff φ = Payoff.Payoff (nakedBidQ96 φ)

-- One-sided invert: mid + ask → FeePips (φ_M channel).
feePipsFromAsk :: PayoffX96 -> PayoffX96 -> FeePips
feePipsFromAsk (PayoffX96 pmid) (PayoffX96 pa)
  | pmid <= 0 || pa <= 0 =
      error "Pricing.Stremia.feePipsFromAsk: mid/ask must be > 0"
  | otherwise =
      let phiX96 = mulX96 pa (invX96 pmid) - Q96
      in  mkFeePips $ (phiX96 * feePipsScale) `div` Q96

-- One-sided invert: mid + bid → FeePips (φ_X channel).
feePipsFromBid :: PayoffX96 -> PayoffX96 -> FeePips
feePipsFromBid (PayoffX96 pmid) (PayoffX96 pb)
  | pmid <= 0 || pb <= 0 =
      error "Pricing.Stremia.feePipsFromBid: mid/bid must be > 0"
  | otherwise =
      let phiX96 = mulX96 pmid (invX96 pb) - Q96
      in  mkFeePips $ (phiX96 * feePipsScale) `div` Q96

-- Invert mid+bid+ask → one FeePips when ask/bid agree (equal-φ special case).
feePipsFromBidAsk :: PayoffX96 -> PayoffX96 -> PayoffX96 -> FeePips
feePipsFromBidAsk mid bid ask =
  let
    pipsAsk = unFeePips (feePipsFromAsk mid ask)
    pipsBid = unFeePips (feePipsFromBid mid bid)
  in
    if abs (pipsAsk - pipsBid) > 1
      then
        error
          "Pricing.Stremia.feePipsFromBidAsk: ask/bid FeePips disagree by > 1 pip"
      else mkFeePips pipsAsk

-- φ ≡ 1 - (1-φ_M)(1-φ_X) in FeePips (Q96 mul).
-- Exact identity when either side is 0 (avoids Q96 trunc on mempty).
compositeFeePips :: FeePips -> FeePips -> FeePips
compositeFeePips (FeePips 0) x = x
compositeFeePips m (FeePips 0) = m
compositeFeePips (FeePips m) (FeePips x) =
  let
    phiMX96 = (m * Q96) `div` feePipsScale
    phiXX96 = (x * Q96) `div` feePipsScale
    oneMinusM = Q96 - phiMX96
    oneMinusX = Q96 - phiXX96
    prod = mulX96 oneMinusM oneMinusX
    phiX96 = Q96 - prod
  in
    mkFeePips $ (phiX96 * feePipsScale) `div` Q96

-- Survival stack: φ₁ <> φ₂ = 1 - (1-φ₁)(1-φ₂). Same path as compositeFeePips.
instance Semigroup FeePips where
  (<>) = compositeFeePips

instance Monoid FeePips where
  mempty = mkFeePips 0

defaultFeePipsGrid :: [FeePips]
defaultFeePipsGrid = map mkFeePips [0, 100 .. 3000]
