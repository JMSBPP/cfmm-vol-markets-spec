{-# LANGUAGE PatternSynonyms #-}

module Pricing.MarkUpStructure
  ( MarkUpStructure(..)
  , TwoSidedMarkUp(..)
  ) where

import Pricing.Stremia
  ( FeeFactorX96(..)
  , FeePips(..)
  , feeFactor
  , mkFeePips
  , unFeeFactorX96
  )
import SqrtGrid (mulX96)

class MarkUpStructure a where
  markUpFactors :: a -> [FeePips]
  foldMarkUpFactor :: a -> FeeFactorX96
  foldMarkUpFactor = defaultFoldMarkUpFactor markUpFactors

class MarkUpStructure a => TwoSidedMarkUp a where
  markupPhiX :: a -> FeePips
  markupPhiM :: a -> FeePips

defaultFoldMarkUpFactor :: (a -> [FeePips]) -> a -> FeeFactorX96
defaultFoldMarkUpFactor factors a =
  let
    go acc m =
      FeeFactorX96 $
        mulX96 (unFeeFactorX96 acc) (unFeeFactorX96 (feeFactor m))
    identity = feeFactor (mkFeePips 0)
  in
    foldl go identity (factors a)
