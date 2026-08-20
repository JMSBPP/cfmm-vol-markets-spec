module Greeks.Vega
  ( Vega(..)
  ) where

import SqrtGrid (SqrtPriceX96)

-- ∂V/∂σ. Stub.
--
-- TODO / open notes (do not treat as settled):
--   - Are all greeks dimensionless?
--   - If Liquidity is dimensionless, can we do
--     vega(Payoff) -> Liquidity for any payoff?
newtype Vega = Vega { runVega :: SqrtPriceX96 -> Rational }
