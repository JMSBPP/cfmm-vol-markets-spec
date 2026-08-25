{-# LANGUAGE PatternSynonyms #-}

-- | Holder-hedged path (rebate note §3–§5; TODO #35, re-scoped #34 / TODO #23).
--
-- Three sources on one tick path:
--   trans  — round-trip noise (the GAMS half; fees, no correction);
--   holder — the position holder moves the pool to the external tick when the
--            gap exceeds the gas threshold (fee-free at the margin: rebate);
--   arb    — residual: closes gaps the holder left, only beyond the fee band.
-- The arb share [ν_arb/ν] is READ OFF the produced path (tick volume), never set.
--
-- Hedging along a path (Prop B): at each step end the holder brings h → Δ̂^σ(p)
-- when |Δ̂^σ(p) − h| > gas (token0); the hedge trade is assumed small against
-- the pool (no own price impact).  Per step, gamma gain
--   γ_k = [π̂^σ(p_{k+1}) − π̂^σ(p_k)] − h_k · (P_{k+1} − P_k)/Q96   (≥ 0 when h_k = Δ̂^σ(p_k))
-- so that holder P&L = Σγ − fees paid + rebates − streamia paid.
module Payoffs.HolderPath
  ( Regime(..)
  , composedPath
  , pathEndTicks
  , arbShare
  , HolderReport(..)
  , hedgeAlong
  , holderPnL
  , trianglePath
  ) where

import Greeks.Delta (PayoffDelta(..), PriceDeltaX96(..))
import Hedge.Ledger (HolderSwap(..), Ledger(..), RebateX96(..), hedgeStep)
import Panoptic.MintPlan (MintPlan)
import Payoffs.PathAccrual (ArbSharePips, Step(..), Tag(..), mkArbSharePips, pattern PIPS_ONE)
import qualified Payoffs.Payoff as Payoff
import Payoffs.ReplicaDelta (replicaDelta)
import Payoffs.VolatilityReplica (fourLegReplica)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), SqrtPriceX96(..), Tick, mulDiv, pattern Q96, sqrtPriceX96)

data Regime = Regime
  { rgGasTicks     :: Int    -- holder corrects when |e − p| > gas
  , rgBandTicks    :: Int    -- residual arb corrects when |e − p| > band
  , rgHolderActive :: Bool
  }
  deriving (Show, Eq)

-- | Deterministic composed path: n rounds of (trans ±transAmp, external ±extAmp,
-- then holder / arb correction per the regime).  Same 32-bit LCG as syntheticPath.
composedPath :: Int -> Tick -> Int -> Int -> Int -> Regime -> [Step]
composedPath seed i0 n transAmp extAmp rg = go 0 i0 i0 (fromIntegral seed :: Integer)
  where
    lcg st = (1664525 * st + 1013904223) `mod` 4294967296
    go k p e st
      | k >= n = []
      | otherwise =
          let st1 = lcg st
              st2 = lcg st1
              p'  = if (st1 `div` 65536) `mod` 2 == 0 then p + transAmp else p - transAmp
              e'  = if (st2 `div` 65536) `mod` 2 == 0 then e + extAmp else e - extAmp
              gap = abs (e' - p')
              trans = Step p p' Trans
              (corr, pEnd)
                | rgHolderActive rg && gap > rgGasTicks rg  = ([Step p' e' Holder], e')
                | gap > rgBandTicks rg                      = ([Step p' e' Arb], e')
                | otherwise                                 = ([], p')
          in  trans : corr ++ go (k + 1) pEnd e' st2

-- | Tick after each step (the ticks at which the holder may hedge).
pathEndTicks :: [Step] -> [Tick]
pathEndTicks = map stepTo

-- | [ν_arb/ν] read off the path: arb tick volume over total tick volume, pips.
arbShare :: [Step] -> ArbSharePips
arbShare steps =
  let vol tag = sum [ toInteger (abs (stepTo s - stepFrom s)) | s <- steps, stepTag s == tag ]
      total = vol Trans + vol Arb + vol Holder
  in  mkArbSharePips (if total == 0 then 0 else mulDiv (vol Arb) PIPS_ONE total)

data HolderReport = HolderReport
  { rpGamma    :: Integer   -- Σγ_k, token1
  , rpFeesPaid :: Integer   -- φ on every hedge trade, token1
  , rpRebates  :: Integer   -- Σρ, token1
  , rpHedges   :: Int
  , rpLedger   :: Ledger
  }
  deriving (Show, Eq)

-- | Hedge the replica along the path; gas in raw token0.
hedgeAlong :: FeePips -> MintPlan -> Integer -> Ledger -> [Step] -> HolderReport
hedgeAlong phi plan gasToken0 led0 steps = go led0 (HolderReport 0 0 0 0 led0) steps
  where
    pStar = sqrtPriceX96 0
    replica = Payoff.runPayoff (fourLegReplica plan pStar)
    PayoffDelta delta = replicaDelta plan
    priceOf (SqrtPriceX96 p) = mulDiv p p Q96
    go led rep [] = rep { rpLedger = led }
    go led rep (Step iFrom iTo _ : rest) =
      let pF = sqrtPriceX96 iFrom
          pT = sqrtPriceX96 iTo
          PayoffX96 vF = replica pF
          PayoffX96 vT = replica pT
          gammaK = (vT - vF) - mulDiv (hedged led) (priceOf pT - priceOf pF) Q96
          PriceDeltaX96 dStar = delta pT
          q = dStar - hedged led
          (led', fee, rho, n)
            | abs q > gasToken0 =
                let SqrtPriceX96 p = pT
                    value1 = mulDiv (mulDiv p p Q96) (abs q) Q96
                    f = mulDiv value1 (unFeePips phi) 1000000
                    (l', RebateX96 r) = hedgeStep phi (PayoffDelta delta) led (HolderSwap pT q)
                in  (l', f, r, 1)
            | otherwise = (led, 0, 0, 0)
      in  go led' rep { rpGamma = rpGamma rep + gammaK
                      , rpFeesPaid = rpFeesPaid rep + fee
                      , rpRebates = rpRebates rep + rho
                      , rpHedges = rpHedges rep + n } rest

-- | Σγ − fees + rebates − streamia (Prop B).
holderPnL :: HolderReport -> Integer
holderPnL rep = rpGamma rep - rpFeesPaid rep + rpRebates rep - streamiaPaid (rpLedger rep)

-- | Round trip i0 → i0 + amp → i0 − amp → i0 in Trans steps of `stride` ticks (p_0 = p_T).
trianglePath :: Tick -> Int -> Int -> [Step]
trianglePath i0 amp stride =
  let up   = [i0, i0 + stride .. i0 + amp]
      down = [i0 + amp, i0 + amp - stride .. i0 - amp]
      back = [i0 - amp, i0 - amp + stride .. i0]
      pts  = up ++ drop 1 down ++ drop 1 back
  in  zipWith (\a b -> Step a b Trans) pts (drop 1 pts)
