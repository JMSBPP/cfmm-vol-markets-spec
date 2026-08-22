module Pricing.FeeStructure
  ( FeeStructure(..)
  , mkFeeStructure
  , toFeePips
  ) where

import Pricing.MarkUpStructure (MarkUpStructure(..), TwoSidedMarkUp(..))
import Pricing.Stremia (FeePips, compositeFeePips)

-- | Two-sided static markup bag \(\{\phi_X,\phi_M\}\). Not a Monoid —
-- monoid lives on 'FeePips' (survival stack). First service: 'toFeePips'.
data FeeStructure = FeeStructure
  { feePhiX :: FeePips
  , feePhiM :: FeePips
  }
  deriving (Show, Eq)

mkFeeStructure :: FeePips -> FeePips -> FeeStructure
mkFeeStructure phiX phiM =
  FeeStructure { feePhiX = phiX, feePhiM = phiM }

-- | \(\phi \equiv 1-(1-\phi_M)(1-\phi_X)\).
toFeePips :: FeeStructure -> FeePips
toFeePips (FeeStructure x m) = compositeFeePips m x

instance MarkUpStructure FeeStructure where
  markUpFactors (FeeStructure x m) = [x, m]

instance TwoSidedMarkUp FeeStructure where
  markupPhiX = feePhiX
  markupPhiM = feePhiM
