-- | Adaptive (volatility) fee — stub.
--
-- References (sigmoid / Algebra dynamic fee):
--
-- 1. Plank notes — Def 18 sum-of-sigmoids dynamic fee schedule:
--    @cfmms-playground/cfmm-wt/plank/notes/VOLATILITY_INSTRUMENTS.md@
--
-- 2. Discrete twin — \(\phi_Z(;\sigma_X)=\sum_j \alpha_j/(1+\exp((\beta_j-\sigma_X)/\gamma_j))\),
--    \(\phi=\bar\phi^{\star}+\phi_Z\):
--    @cfmm-theory/cfmm-discrete/FINANCE.md@ (§ Adaptive fee & realized variance)
--
-- 3. On-chain twin — @cryptoalgebra/dynamic-fee-plugin@
--    @contracts/libraries/AdaptiveFee.sol@
--    (@getFee@ = baseFee + sigmoid1 + sigmoid2; @sigmoid@ = α/(1+e^{(β-x)/γ}))
--
-- Relation to @Pricing.Stremia@: static Algebra @FeePips@ / bid-ask markup.
-- This module will own the σ-adaptive surcharge that feeds those @FeePips@.
module Pricing.AdaptiveStremia
  ( AdaptiveStremia(..)
  , adaptiveFeePips
  ) where

import Pricing.Stremia (FeePips)

-- | Placeholder for Algebra fee configuration / adaptive state.
newtype AdaptiveStremia = AdaptiveStremia Integer
  deriving (Show, Eq)

-- | Stub: twin of @AdaptiveFee.getFee@ → @FeePips@.
-- Not implemented — see module refs.
adaptiveFeePips :: AdaptiveStremia -> FeePips
adaptiveFeePips _ =
  error
    "Pricing.AdaptiveStremia.adaptiveFeePips: stub — sigmoid twin of AdaptiveFee.getFee"
