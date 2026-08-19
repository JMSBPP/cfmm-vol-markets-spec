module Volatility.CevField
  ( cevLayoutVsSqrtPrice
  , cevLayoutVsGamma
  , cevLayoutVsXi
  ) where

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
import SqrtGrid
  ( Tick
  , TickSpacing
  , sqrtPriceX96
  , toDouble
  , unTickSpacing
  )
import Volatility.VolatilityGrid (gammaCoordinate)
import Volatility.VolTermStructure
  ( Step(..)
  , VolTermStructure(..)
  , unInstantaneousVol
  )

rungTick :: Tick -> TickSpacing -> Int -> Tick
rungTick iMin spacing x =
  iMin + x * unTickSpacing spacing

cevLayoutAgainst
  :: String
  -> String
  -> (Int -> Tick -> Double)
  -> VolTermStructure
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
cevLayoutAgainst title xTitle xAt vts spacing iMin iota
  | unLadderResolution iota < 1 =
      error "Volatility.CevField.cevLayoutAgainst: ι must be ≥ 1"
  | otherwise = execEC $ do
    let
      n = unLadderResolution iota
      pts =
        [ ( xAt x i
          , unInstantaneousVol (volAt vts i (Step 0))
          )
        | x <- [0 .. n - 1]
        , let i = rungTick iMin spacing x
        ]
    layout_title .= title
    layout_x_axis . laxis_title .= xTitle
    layout_y_axis . laxis_title .= "volAt (CEV σ(i))"
    setColors [opaque blue]
    plot $ line "volAt" [pts]

cevLayoutVsSqrtPrice
  :: VolTermStructure
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
cevLayoutVsSqrtPrice vts spacing iMin iota =
  cevLayoutAgainst
    "CEV σ(i)=δ/p_{1/2}(i) on sqrtPriceX96"
    "sqrtPriceX96"
    (\ _x i -> toDouble (sqrtPriceX96 i))
    vts
    spacing
    iMin
    iota

cevLayoutVsGamma
  :: VolTermStructure
  -> Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
cevLayoutVsGamma vts xiWord eta spacing iMin iota =
  cevLayoutAgainst
    "CEV σ(i)=δ/p_{1/2}(i) on gammaCoordinate"
    "uint256 gammaCoordinate"
    (\ _x i -> fromInteger (gammaCoordinate xiWord eta spacing i))
    vts
    spacing
    iMin
    iota

cevLayoutVsXi
  :: VolTermStructure
  -> XiX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
cevLayoutVsXi vts xi spacing iMin iota =
  cevLayoutAgainst
    "CEV σ(i)=δ/p_{1/2}(i) on xiCoordinate"
    "xiCoordinate (Q96)"
    (\ x _i -> fromInteger (unXiX96 (xiCoordinate xi x)))
    vts
    spacing
    iMin
    iota
