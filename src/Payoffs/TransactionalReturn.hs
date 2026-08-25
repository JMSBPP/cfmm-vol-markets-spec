{-# LANGUAGE PatternSynonyms #-}

-- | Reference transactional return r^φ = φ·δ_trans (TODO #7 / #3; README MODEL_CLOSURE §1).
--
-- δ_trans is the transactional turnover of the position's token1 notional N:
--   δ_X = Σ_{trans, down} amount_in / N  (token0 paid in, valued at p_j)
--   δ_M = Σ_{trans, up}   amount_in / N  (token1 paid in)
-- and, because the fee is charged on the token paid in (Payoffs.PathAccrual.stepAccrual),
--   r^φ = fees_trans / N = φ_X δ_X + φ_M δ_M          (exact up to X96 floors)
--       = φ δ_trans                                     when φ_X = φ_M = φ.
-- This is a RETURN (ReturnPips, uint24 pips of N), distinct from the payoff π^φ; it is
-- independent of r^e_trans when the two fees coincide (MODEL_CLOSURE §1).
module Payoffs.TransactionalReturn
  ( TransTurnover(..)
  , transTurnover
  , refTransactionalReturn
  , measuredFeeReturn
  ) where

import Liquidity.LiquidityChunk (LiquidityChunk)
import Payoffs.PathAccrual (Accrual(..), Step(..), Tag(..), addAccrual, pathAccrual, stepVolume1, zeroAccrual)
import Payoffs.Return (ReturnPips(..), returnPipsScale)
import Pricing.Stremia (FeePips, unFeePips)
import SqrtGrid (PayoffX96(..), mulDiv)

-- | δ_trans by token side, pips of the notional N.
data TransTurnover = TransTurnover
  { turnoverX :: Integer   -- down moves (token0 in), pips
  , turnoverM :: Integer   -- up moves (token1 in), pips
  }
  deriving (Show, Eq)

transTurnover :: [LiquidityChunk] -> [Step] -> PayoffX96 -> TransTurnover
transTurnover chs steps (PayoffX96 n)
  | n <= 0 = error "Payoffs.TransactionalReturn.transTurnover: notional must be > 0"
  | otherwise =
      let vol dir = sum [ stepVolume1 ch st | ch <- chs, st <- steps, stepTag st == Trans, dir st ]
          down st = stepTo st < stepFrom st
          up st   = stepTo st > stepFrom st
      in  TransTurnover (mulDiv (vol down) returnPipsScale n) (mulDiv (vol up) returnPipsScale n)

-- | r^φ = φ_X δ_X + φ_M δ_M, pips.
refTransactionalReturn :: FeePips -> FeePips -> TransTurnover -> ReturnPips
refTransactionalReturn phiX phiM (TransTurnover dX dM) =
  ReturnPips (mulDiv (unFeePips phiX) dX returnPipsScale + mulDiv (unFeePips phiM) dM returnPipsScale)

-- | fees_trans / N read off the accrual, pips — the thing r^φ must equal.
measuredFeeReturn :: FeePips -> FeePips -> [LiquidityChunk] -> [Step] -> PayoffX96 -> ReturnPips
measuredFeeReturn phiX phiM chs steps (PayoffX96 n) =
  let acc = foldr addAccrual zeroAccrual [ pathAccrual phiX phiM ch steps | ch <- chs ]
  in  ReturnPips (mulDiv (feesTrans acc) returnPipsScale n)
