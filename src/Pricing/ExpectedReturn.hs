module Pricing.ExpectedReturn
  ( ExpectedReturn(..)
  , unExpectedReturn
  , ReturnFromKappa(..)
  ) where

import Pricing.FeeStructure (FeeStructure(..))
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

instance ReturnFromKappa FeeStructure where
  returnFromKappa coord (FeeStructure φX φM) =
    let
      (j, n) = kappaJN coord
      px = unFeePips φX
      pm = unFeePips φM
    in
      ExpectedReturn $
        mkFeePips $
          ((fromIntegral (n - j) * px) + (fromIntegral j * pm))
            `div` fromIntegral n

instance ReturnFromKappa FeePips where
  returnFromKappa coord φ =
    let
      (j, n) = kappaJN coord
    in
      ExpectedReturn $
        mkFeePips $
          (fromIntegral j * unFeePips φ) `div` fromIntegral n
