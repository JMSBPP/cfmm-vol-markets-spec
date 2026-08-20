module Payoffs.VariancePortfolio
  ( VariancePortfolio
  , fromLegs
  , fromDef6
  , toPayoff
  , scaleByTargetVega
  , variancePortfolioLayout
  , variancePortfolioLayoutVsGamma
  , variancePortfolioLayoutVsXi
  ) where

import Control.Exception (assert)
import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Easy
import Liquidity.LiquidityGrid
  ( LadderResolution
  , XiX96
  , unLadderResolution
  , unXiX96
  , xiCoordinate
  )
import Pricing.PriceDeformation (EtaX96)
import qualified Payoffs.Payoff as Payoff
import Payoffs.Forward
  ( AtmForward
  , forward
  , nakedForwardQ96
  , unAtmForward
  )
import Payoffs.Log (logContract, nakedLogQ96)
import Payoffs.NId (MintPlan, NId, scaleByNId)
import Payoffs.TargetVega (TargetVega, targetVegaFromMint, unTargetVega)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , Tick
  , TickSpacing
  , sqrtPriceX96
  , toDouble
  , unTickSpacing
  )
import Volatility.VolatilityGrid (gammaCoordinate)

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

hopBScaled
  :: MintPlan
  -> NId
  -> AtmForward
  -> PayoffX96
  -> Payoff.Payoff
hopBScaled plan nId atm remaining =
  scaleByTargetVega (targetVegaFromMint plan) (fromLegs nId atm remaining)

rungTick :: Tick -> TickSpacing -> Int -> Tick
rungTick iMin spacing x =
  iMin + x * unTickSpacing spacing

atmInterior :: Tick -> TickSpacing -> LadderResolution -> Bool
atmInterior iMin spacing iota =
  let
    n = unLadderResolution iota
    iMax = iMin + (n - 1) * unTickSpacing spacing
  in
    iMin < 0 && iMax > 0

variancePortfolioLayoutAgainst
  :: String
  -> String
  -> (Int -> Tick -> Double)
  -> MintPlan
  -> NId
  -> AtmForward
  -> PayoffX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
variancePortfolioLayoutAgainst title xTitle xAt plan nId atm remaining spacing iMin iota
  | unLadderResolution iota < 2 =
      error "Payoffs.VariancePortfolio: ι must be ≥ 2"
  | not (atmInterior iMin spacing iota) =
      error "Payoffs.VariancePortfolio: two-sided ladder must contain ATM in the interior"
  | otherwise = execEC $ do
    let
      pf = hopBScaled plan nId atm remaining
      n = unLadderResolution iota
      pts =
        [ ( xAt x i
          , fromInteger y
          )
        | x <- [0 .. n - 1]
        , let i = rungTick iMin spacing x
        , let PayoffX96 y = Payoff.runPayoff pf (sqrtPriceX96 i)
        ]
    layout_title .= title
    layout_x_axis . laxis_title .= xTitle
    layout_y_axis . laxis_title .= "PayoffX96"
    setColors [opaque blue]
    plot $ line "HopB" [pts]

variancePortfolioLayoutVsGamma
  :: MintPlan
  -> NId
  -> AtmForward
  -> PayoffX96
  -> Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
variancePortfolioLayoutVsGamma plan nId atm remaining xiWord eta spacing iMin iota =
  variancePortfolioLayoutAgainst
    "Hop B Π_σ opt × ΔQ_v on gammaCoordinate"
    "uint256 gammaCoordinate"
    (\ _x i -> fromInteger (gammaCoordinate xiWord eta spacing i))
    plan
    nId
    atm
    remaining
    spacing
    iMin
    iota

variancePortfolioLayoutVsXi
  :: MintPlan
  -> NId
  -> AtmForward
  -> PayoffX96
  -> XiX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
variancePortfolioLayoutVsXi plan nId atm remaining xi spacing iMin iota =
  variancePortfolioLayoutAgainst
    "Hop B Π_σ opt × ΔQ_v on xiCoordinate"
    "xiCoordinate (Q96)"
    (\ x _i -> fromInteger (unXiX96 (xiCoordinate xi x)))
    plan
    nId
    atm
    remaining
    spacing
    iMin
    iota
