{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PatternSynonyms #-}

module Payoffs.Swap
  ( Side(..)
  , Leg(..)
  , Swap(..)
  , mkSwap
  , survivalFactorX96
  , scalePayoffX96
  , swapFromMarkUp
  , swapFromFeeStructure
  , expectedReturnWeightX96
  , swapFromExpectedReturn
  , runSwapNet
  , runSwapAlongTenor
  , runSwapAlongTenorMixture
  , swapParameterized
  ) where

import Payoffs.Linear (linearPayoff)
import Payoffs.Payoff (Payoff(..), subPayoff)
import Payoffs.Savings (savingsPayoff)
import Pricing.ExpectedReturn
  ( ExpectedReturn(..)
  , returnFromKappaTwoSided
  )
import Pricing.FeeStructure (FeeStructure)
import Pricing.MarkUpStructure (TwoSidedMarkUp(..))
import Pricing.InterestPriceMap (InterestPriceMap, priceTickAt)
import Pricing.InterestSqrt
  ( InterestSqrtX96
  , InterestTick
  , interestSqrtX96
  )
import Pricing.Stremia (FeePips(..), feePipsScale, unFeePips)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96
  , mulX96
  , pattern Q96
  , sqrtPriceX96
  )
import Trading.KappaCoordinate (KappaCoordinate)

-- | Pay vs receive polarity (phantom / DataKinds).
data Side = Pay | Receive

newtype Leg (s :: Side) u = Leg (Payoff u)

-- | Opposite sides only: Pay leg + Receive leg.
data Swap (sPay :: Side) (sRecv :: Side) uPay uRecv where
  Swap
    :: Leg 'Pay uPay
    -> Leg 'Receive uRecv
    -> Swap 'Pay 'Receive uPay uRecv

mkSwap
  :: Payoff uPay
  -> Payoff uRecv
  -> Swap 'Pay 'Receive uPay uRecv
mkSwap payPf recvPf = Swap (Leg payPf) (Leg recvPf)

-- | \((1-\phi)_{\mathrm{X96}}\).
survivalFactorX96 :: FeePips -> Integer
survivalFactorX96 (FeePips p) =
  Q96 - ((p * Q96) `div` feePipsScale)

scalePayoffX96 :: Integer -> PayoffX96 -> PayoffX96
scalePayoffX96 f (PayoffX96 y) = PayoffX96 (mulX96 y f)

-- | Pay = Linear×(1-φ_X); Receive = Savings×(1-φ_M).
swapFromMarkUp
  :: TwoSidedMarkUp a
  => a
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
swapFromMarkUp mu =
  let
    φX = markupPhiX mu
    φM = markupPhiM mu
  in
    mkSwap
      (Payoff $ \s ->
          scalePayoffX96 (survivalFactorX96 φX) (linearPayoff s))
      (Payoff $ \sr ->
          scalePayoffX96 (survivalFactorX96 φM) (savingsPayoff sr))

swapFromFeeStructure
  :: FeeStructure
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
swapFromFeeStructure = swapFromMarkUp

-- | Mixture weight \(w\) as Q96 fraction from \(r^e\) pips.
expectedReturnWeightX96 :: ExpectedReturn -> Integer
expectedReturnWeightX96 (ExpectedReturn φ) =
  let
    w = (unFeePips φ * Q96) `div` feePipsScale
  in
    max 0 (min Q96 w)

-- | Same leg shapes as 'swapFromFeeStructure'; weight applied at mixture eval.
swapFromExpectedReturn
  :: TwoSidedMarkUp a
  => ExpectedReturn
  -> a
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
swapFromExpectedReturn _re mu = swapFromMarkUp mu

-- | Same-u net: \(Y_{\mathrm{recv}}-Y_{\mathrm{pay}}\).
runSwapNet
  :: Swap 'Pay 'Receive u u
  -> Payoff u
runSwapNet (Swap (Leg pay) (Leg recv)) = subPayoff recv pay

-- | Mixed FeeStructure path: \(Y(t)=Y_{\mathrm{recv}}(s_r(t))-Y_{\mathrm{pay}}(s(i(t)))\).
runSwapAlongTenor
  :: InterestPriceMap
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
  -> InterestTick
  -> PayoffX96
runSwapAlongTenor ipm (Swap (Leg pay) (Leg recv)) t =
  let
    PayoffX96 yr = runPayoff recv (interestSqrtX96 t)
    PayoffX96 yp =
      runPayoff pay (sqrtPriceX96 (priceTickAt ipm t))
  in
    PayoffX96 (yr - yp)

-- | \(\pi^{\Delta Q}(r^e)\): \(Y=(1-w)Y_{\mathrm{pay}}+w\,Y_{\mathrm{recv}}\).
runSwapAlongTenorMixture
  :: InterestPriceMap
  -> ExpectedReturn
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
  -> InterestTick
  -> PayoffX96
runSwapAlongTenorMixture ipm re (Swap (Leg pay) (Leg recv)) t =
  let
    w = expectedReturnWeightX96 re
    PayoffX96 yr = runPayoff recv (interestSqrtX96 t)
    PayoffX96 yp =
      runPayoff pay (sqrtPriceX96 (priceTickAt ipm t))
    y = mulX96 yp (Q96 - w) + mulX96 yr w
  in
    PayoffX96 y

-- | \(\kappa\) + FeeStructure → ExpectedReturn → same legs as fee-structure swap.
swapParameterized
  :: TwoSidedMarkUp a
  => KappaCoordinate
  -> a
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
swapParameterized κ mu =
  swapFromExpectedReturn (returnFromKappaTwoSided κ mu) mu
