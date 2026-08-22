{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE PatternSynonyms #-}

module Payoffs.TransactionalFeeCapture
  ( TransactionalFeeCapture(..)
  , feeFactorX96
  , transactionalFeeCaptureFromMarkUp
  , transactionalFeeCaptureFromFeeStructure
  , feeRevenueExpectedReturn
  , runFeeCaptureAlongTenor
  , runFeeCaptureAlongTenorMixture
  , payPartitionErrorX96
  , recvPartitionErrorX96
  , assertAccountingIdentityWithSwap
  ) where

import Payoffs.Linear (linearPayoff)
import Payoffs.Payoff (Payoff(..), runPayoff)
import Payoffs.Savings (savingsPayoff)
import Payoffs.Swap
  ( Leg(..)
  , Side(..)
  , Swap(..)
  , expectedReturnWeightX96
  , scalePayoffX96
  , swapFromMarkUp
  )
import Pricing.ExpectedReturn (ExpectedReturn(..), unExpectedReturn)
import Pricing.FeeStructure (FeeStructure(..), toFeePips)
import Pricing.MarkUpStructure (TwoSidedMarkUp(..))
import Pricing.InterestPriceMap (InterestPriceMap, priceTickAt)
import Pricing.InterestSqrt
  ( InterestSqrtX96
  , InterestTick
  , interestSqrtX96
  )
import Pricing.Stremia (FeePips(..), feePipsScale, mkFeePips, unFeePips)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96
  , mulX96
  , pattern Q96
  , sqrtPriceX96
  )

-- | Fee-take twin of 'Swap': \(\pi^\phi=\phi_X P+\phi_M I\).
data TransactionalFeeCapture (sPay :: Side) (sRecv :: Side) uPay uRecv where
  TransactionalFeeCapture
    :: Leg 'Pay uPay
    -> Leg 'Receive uRecv
    -> TransactionalFeeCapture 'Pay 'Receive uPay uRecv

-- | \(\phi\) as Q96 fraction.
feeFactorX96 :: FeePips -> Integer
feeFactorX96 (FeePips p) = (p * Q96) `div` feePipsScale

transactionalFeeCaptureFromMarkUp
  :: TwoSidedMarkUp a
  => a
  -> TransactionalFeeCapture 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
transactionalFeeCaptureFromMarkUp mu =
  let
    φX = markupPhiX mu
    φM = markupPhiM mu
  in
    TransactionalFeeCapture
      (Leg $ Payoff $ \s ->
          scalePayoffX96 (feeFactorX96 φX) (linearPayoff s))
      (Leg $ Payoff $ \sr ->
          scalePayoffX96 (feeFactorX96 φM) (savingsPayoff sr))

transactionalFeeCaptureFromFeeStructure
  :: FeeStructure
  -> TransactionalFeeCapture 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
transactionalFeeCaptureFromFeeStructure = transactionalFeeCaptureFromMarkUp

-- | \(r_\phi^e=\phi\cdot r^e\) with \(\phi=\phi_M\otimes\phi_X\).
feeRevenueExpectedReturn
  :: FeeStructure
  -> ExpectedReturn
  -> ExpectedReturn
feeRevenueExpectedReturn fs re =
  let
    φ = toFeePips fs
    r = unExpectedReturn re
  in
    ExpectedReturn $
      mkFeePips $
        (unFeePips φ * unFeePips r) `div` feePipsScale

-- | \(Y=Y_{\mathrm{pay}}+Y_{\mathrm{recv}}\) along \(i=kt+i_0\).
runFeeCaptureAlongTenor
  :: InterestPriceMap
  -> TransactionalFeeCapture 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
  -> InterestTick
  -> PayoffX96
runFeeCaptureAlongTenor ipm (TransactionalFeeCapture (Leg pay) (Leg recv)) t =
  let
    PayoffX96 yr = runPayoff recv (interestSqrtX96 t)
    PayoffX96 yp =
      runPayoff pay (sqrtPriceX96 (priceTickAt ipm t))
  in
    PayoffX96 (yp + yr)

-- | \(\pi^\phi(r_\phi^e)\): \(Y=(1-w)Y_{\mathrm{pay}}+w\,Y_{\mathrm{recv}}\).
-- Caller supplies \(r_\phi^e\) (e.g. via 'feeRevenueExpectedReturn').
runFeeCaptureAlongTenorMixture
  :: InterestPriceMap
  -> ExpectedReturn
  -> TransactionalFeeCapture 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
  -> InterestTick
  -> PayoffX96
runFeeCaptureAlongTenorMixture ipm rPhiE (TransactionalFeeCapture (Leg pay) (Leg recv)) t =
  let
    w = expectedReturnWeightX96 rPhiE
    PayoffX96 yr = runPayoff recv (interestSqrtX96 t)
    PayoffX96 yp =
      runPayoff pay (sqrtPriceX96 (priceTickAt ipm t))
    y = mulX96 yp (Q96 - w) + mulX96 yr w
  in
    PayoffX96 y

-- | \(|Y_{\mathrm{capture}}+Y_{\mathrm{swap}}-Y_{\mathrm{linear}}|\).
payPartitionErrorX96 :: TwoSidedMarkUp a => a -> SqrtPriceX96 -> Integer
payPartitionErrorX96 mu s =
  let
    TransactionalFeeCapture (Leg cap) _ =
      transactionalFeeCaptureFromMarkUp mu
    Swap (Leg surv) _ = swapFromMarkUp mu
    PayoffX96 yc = runPayoff cap s
    PayoffX96 ys = runPayoff surv s
    PayoffX96 yn = linearPayoff s
  in
    abs (yc + ys - yn)

-- | \(|Y_{\mathrm{capture}}+Y_{\mathrm{swap}}-Y_{\mathrm{savings}}|\).
recvPartitionErrorX96 :: TwoSidedMarkUp a => a -> InterestSqrtX96 -> Integer
recvPartitionErrorX96 mu sr =
  let
    TransactionalFeeCapture _ (Leg cap) =
      transactionalFeeCaptureFromMarkUp mu
    Swap _ (Leg surv) = swapFromMarkUp mu
    PayoffX96 yc = runPayoff cap sr
    PayoffX96 ys = runPayoff surv sr
    PayoffX96 yn = savingsPayoff sr
  in
    abs (yc + ys - yn)

assertAccountingIdentityWithSwap
  :: TwoSidedMarkUp a => a -> SqrtPriceX96 -> InterestSqrtX96 -> ()
assertAccountingIdentityWithSwap mu s sr
  | payPartitionErrorX96 mu s > 1 =
      error
        "Payoffs.TransactionalFeeCapture: pay partition vs Swap exceeds 1 X96"
  | recvPartitionErrorX96 mu sr > 1 =
      error
        "Payoffs.TransactionalFeeCapture: recv partition vs Swap exceeds 1 X96"
  | otherwise = ()
