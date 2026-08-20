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
  , swapFromFeeStructure
  , runSwapNet
  , runSwapAlongTenor
  ) where

import Payoffs.Linear (linearPayoff)
import Payoffs.Payoff (Payoff(..), subPayoff)
import Payoffs.Savings (savingsPayoff)
import Pricing.FeeStructure (FeeStructure(..))
import Pricing.InterestPriceMap (InterestPriceMap, priceTickAt)
import Pricing.InterestSqrt
  ( InterestSqrtX96
  , InterestTick
  , interestSqrtX96
  )
import Pricing.Stremia (FeePips(..), feePipsScale)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96
  , mulX96
  , pattern Q96
  , sqrtPriceX96
  )

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
swapFromFeeStructure
  :: FeeStructure
  -> Swap 'Pay 'Receive SqrtPriceX96 InterestSqrtX96
swapFromFeeStructure (FeeStructure φX φM) =
  mkSwap
    (Payoff $ \s ->
        scalePayoffX96 (survivalFactorX96 φX) (linearPayoff s))
    (Payoff $ \sr ->
        scalePayoffX96 (survivalFactorX96 φM) (savingsPayoff sr))

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
