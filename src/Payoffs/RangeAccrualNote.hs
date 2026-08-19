{-# LANGUAGE PatternSynonyms #-}

module Payoffs.RangeAccrualNote
  ( payoff
  , rangeAccrualNote
  , plotPayoff
  ) where

import qualified Payoffs.Payoff as Payoff

import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot
  , plotSqrtFunction
  )

import StrikeX96 (StrikeX96(..))
import OptionRatio (OptionRatio(..))

payoff :: SqrtPriceX96 -> StrikeX96 -> OptionRatio -> PayoffX96
payoff (SqrtPriceX96 p) k@(StrikeX96 kRaw) ro@(OptionRatio r)
  | p < lowerBound k ro  = PayoffX96 0
  | p < kRaw             = PayoffX96 $ floor (fromInteger (lowerArmNumerator p kRaw r) / (r - 1))
  | p < upperBound k ro  = PayoffX96 $ floor (fromInteger (upperArmNumerator p kRaw r) / (r - 1))
  | otherwise            = PayoffX96 0

rangeAccrualNote :: StrikeX96 -> OptionRatio -> Payoff.Payoff
rangeAccrualNote k r = Payoff.Payoff (\p -> payoff p k r)

plotPayoff :: FilePath -> SqrtPlot -> StrikeX96 -> OptionRatio -> IO ()
plotPayoff path config k r =
  plotSqrtFunction path config [Payoff.runPayoff (rangeAccrualNote k r)]

-- Lower boundary: kappa / sqrt(r)  in X96
lowerBound :: StrikeX96 -> OptionRatio -> Integer
lowerBound (StrikeX96 k) (OptionRatio r) =
  floor (fromInteger k / sqrt r)

-- Upper boundary: kappa * sqrt(r)  in X96
upperBound :: StrikeX96 -> OptionRatio -> Integer
upperBound (StrikeX96 k) (OptionRatio r) =
  floor (fromInteger k * sqrt r)

-- 2*p*k*sqrt(r) - p^2*r - k^2  (lower arm numerator), result in X96
lowerArmNumerator :: Integer -> Integer -> Double -> Integer
lowerArmNumerator p k r =
  let sqrtR = sqrt r
      term1 = 2 * fromInteger (p * k `div` q96) * sqrtR
      term2 = fromInteger (p * p `div` q96) * r
      term3 = fromInteger (k * k `div` q96)
  in  floor (term1 - term2 - term3)
  where q96 = 79228162514264337593543950336

-- 2*p*k*sqrt(r) - p^2 - k^2*r  (upper arm numerator), result in X96
upperArmNumerator :: Integer -> Integer -> Double -> Integer
upperArmNumerator p k r =
  let sqrtR = sqrt r
      term1 = 2 * fromInteger (p * k `div` q96) * sqrtR
      term2 = fromInteger (p * p `div` q96)
      term3 = fromInteger (k * k `div` q96) * r
  in  floor (term1 - term2 - term3)
  where q96 = 79228162514264337593543950336
