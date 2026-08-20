module Greeks.Theta
  ( Theta(..)
  ) where

import SqrtGrid (SqrtPriceX96)

-- ∂V/∂t. Stub.
newtype Theta = Theta { runTheta :: SqrtPriceX96 -> Rational }
