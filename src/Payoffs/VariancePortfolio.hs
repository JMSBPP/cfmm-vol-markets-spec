module Payoffs.VariancePortfolio
  ( VariancePortfolio
  , fromLegs
  , fromDef6
  , toPayoff
  , scaleByTargetVega
  , variancePortfolioLayout
  ) where

import Control.Exception (assert)
import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy
import qualified Payoffs.Payoff as Payoff
import Payoffs.Forward
  ( AtmForward
  , forward
  , nakedForwardQ96
  , unAtmForward
  )
import Payoffs.Log (logContract, nakedLogQ96)
import Payoffs.NId (NId, scaleByNId)
import Payoffs.TargetVega (TargetVega, unTargetVega)
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , toDouble
  )

newtype VariancePortfolio = VariancePortfolio Payoff.Payoff

constantPayoff :: PayoffX96 -> Payoff.Payoff
constantPayoff y = Payoff.Payoff (\_ -> y)

fromLegs :: NId -> AtmForward -> PayoffX96 -> VariancePortfolio
fromLegs nId atm remaining =
  let
    legs =
      Payoff.addPayoff
        (Payoff.subPayoff (forward nId atm) (logContract nId atm))
        (constantPayoff remaining)
    witness = unAtmForward atm
    y = Payoff.runPayoff legs witness
  in
    assert (y == remaining) (VariancePortfolio legs)

fromDef6 :: NId -> AtmForward -> PayoffX96 -> VariancePortfolio
fromDef6 nId atm remaining =
  let
    pf = Payoff.Payoff $ \spot ->
      let
        PayoffX96 f = nakedForwardQ96 spot atm
        PayoffX96 l = nakedLogQ96 spot atm
        PayoffX96 r = remaining
      in
        PayoffX96 (scaleByNId nId (f - l) + r)
    witness = unAtmForward atm
    y = Payoff.runPayoff pf witness
  in
    assert (y == remaining) (VariancePortfolio pf)

toPayoff :: VariancePortfolio -> Payoff.Payoff
toPayoff (VariancePortfolio p) = p

scaleByTargetVega :: TargetVega -> VariancePortfolio -> Payoff.Payoff
scaleByTargetVega dqv (VariancePortfolio (Payoff.Payoff pf)) =
  Payoff.Payoff $ \spot ->
    let PayoffX96 y = pf spot
    in  PayoffX96 (unTargetVega dqv * y)

variancePortfolioLayout
  :: NId
  -> AtmForward
  -> PayoffX96
  -> TargetVega
  -> SqrtPriceX96
  -> SqrtPriceX96
  -> Layout Double Double
variancePortfolioLayout nId atm remaining dqv xLo xHi = execEC $ do
  let
    pf = scaleByTargetVega dqv (fromLegs nId atm remaining)
    SqrtPriceX96 lo = xLo
    SqrtPriceX96 hi = xHi
    step = max 1 ((hi - lo) `div` 400)
    pts =
      [ ( toDouble s
        , fromInteger y
        )
      | raw <- [lo, lo + step .. hi]
      , let s = SqrtPriceX96 raw
      , let PayoffX96 y = Payoff.runPayoff pf s
      ]
  layout_title .= "Π_σ opt × ΔQ_v on sqrtPriceX96"
  layout_x_axis . laxis_title .= "sqrtPriceX96"
  layout_y_axis . laxis_title .= "PayoffX96"
  setColors [opaque blue]
  plot $ line "VariancePortfolio" [pts]
