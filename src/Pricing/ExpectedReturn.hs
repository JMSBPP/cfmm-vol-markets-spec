{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}

module Pricing.ExpectedReturn
  ( ExpectedReturn(..)
  , unExpectedReturn
  , ReturnFromKappa(..)
  , returnFromKappaTwoSided
  ) where

import Pricing.MarkUpStructure (TwoSidedMarkUp(..))
import Pricing.Stremia (FeePips(..), mkFeePips, unFeePips)
import Trading.KappaCoordinate
  ( KappaCoordinate(..)
  , defaultKappaSpacing
  , unKappaSpacing
  , unKappaTick
  )

-- ---------------------------------------------------------------------------
-- VISIBLE NOTE — ExpectedReturn composition (deferred)
--
-- This cycle: FeePips path uses r(0)=0 (r = κ·φ).
-- Later: ExpectedReturn <> Realized / other expecteds supplies r(0).
-- Mirrored in scratchpad/README.md and the design spec.
-- ---------------------------------------------------------------------------

newtype ExpectedReturn = ExpectedReturn FeePips
  deriving (Show, Eq)

unExpectedReturn :: ExpectedReturn -> FeePips
unExpectedReturn (ExpectedReturn φ) = φ

class ReturnFromKappa a where
  returnFromKappa :: KappaCoordinate -> a -> ExpectedReturn

kappaJN :: KappaCoordinate -> (Int, Int)
kappaJN (KappaCoordinate tick) =
  (unKappaTick tick, unKappaSpacing defaultKappaSpacing)

returnFromKappaTwoSided
  :: TwoSidedMarkUp a
  => KappaCoordinate
  -> a
  -> ExpectedReturn
returnFromKappaTwoSided coord mu =
  let
    (j, n) = kappaJN coord
    px = unFeePips (markupPhiX mu)
    pm = unFeePips (markupPhiM mu)
  in
    ExpectedReturn $
      mkFeePips $
        ((fromIntegral (n - j) * px) + (fromIntegral j * pm))
          `div` fromIntegral n

instance {-# OVERLAPPABLE #-} TwoSidedMarkUp a => ReturnFromKappa a where
  returnFromKappa = returnFromKappaTwoSided

instance {-# OVERLAPPING #-} ReturnFromKappa FeePips where
  returnFromKappa coord φ =
    let
      (j, n) = kappaJN coord
    in
      ExpectedReturn $
        mkFeePips $
          (fromIntegral j * unFeePips φ) `div` fromIntegral n
