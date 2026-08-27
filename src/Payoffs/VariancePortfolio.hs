-- | T0 — the continuum variance portfolio (Hop A/B), REFERENCE / DIAGNOSTIC ONLY.
-- Π^σ_opt(P) = N_id·[(P − P*)/P* − ln(P/P*)] + R, built from the single T0
-- definition `Payoffs.Log.logPortfolioQ96` (continuous lnQ96).  It is NOT a
-- position: a strike continuum is not EVM-realizable.  The realizable
-- benchmark is T1 (`Payoffs.LadderPosition`, Theorem 10: T1/N_1 → c(S)·this),
-- and the replica error `VolatilityReplica.replicaError` is T2 vs T1.
-- README § REPLICATION_THEORY Def 7; TODO #29.
module Payoffs.VariancePortfolio
  ( VariancePortfolio
  , fromLegs
  , fromDef6
  , toPayoff
  , scaleByTargetVega
  ) where

import Control.Exception (assert)
import qualified Payoffs.Payoff as Payoff
import Payoffs.Forward
  ( AtmForward
  , unAtmForward
  )
import Payoffs.Log (logPortfolioQ96)
import Panoptic.NId (NId, scaleByNId)
import TargetVega (TargetVega, unTargetVega)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  )

newtype VariancePortfolio = VariancePortfolio (Payoff.Payoff SqrtPriceX96)

-- | Single T0 definition: N_id · logPortfolioQ96 + R  (asserted = R at P*).
fromDef6 :: NId -> AtmForward -> PayoffX96 -> VariancePortfolio
fromDef6 nId atm remaining =
  let
    pf = Payoff.Payoff $ \spot ->
      let
        PayoffX96 lp = logPortfolioQ96 spot (unAtmForward atm)
        PayoffX96 r = remaining
      in
        PayoffX96 (scaleByNId nId lp + r)
    witness = unAtmForward atm
    y = Payoff.runPayoff pf witness
  in
    assert (y == remaining) (VariancePortfolio pf)

-- | Historical "legs" constructor (forward − log contract): now the same
-- definition (TODO #29 — one T0, no second code path).
fromLegs :: NId -> AtmForward -> PayoffX96 -> VariancePortfolio
fromLegs = fromDef6

toPayoff :: VariancePortfolio -> Payoff.Payoff SqrtPriceX96
toPayoff (VariancePortfolio p) = p

scaleByTargetVega :: TargetVega -> VariancePortfolio -> Payoff.Payoff SqrtPriceX96
scaleByTargetVega dqv (VariancePortfolio (Payoff.Payoff pf)) =
  Payoff.Payoff $ \spot ->
    let PayoffX96 y = pf spot
    in  PayoffX96 (unTargetVega dqv * y)
