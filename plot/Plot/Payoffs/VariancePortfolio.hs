-- | Chart layouts for 'Payoffs.VariancePortfolio'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.VariancePortfolio
  ( variancePortfolioLayout
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
  , unAtmForward
  )
import Payoffs.Log (logPortfolioQ96)
import Panoptic.NId (MintPlan, NId, scaleByNId)
import TargetVega (TargetVega, targetVegaFromMint, unTargetVega)
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
import Payoffs.VariancePortfolio


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
  -> Payoff.Payoff SqrtPriceX96
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
