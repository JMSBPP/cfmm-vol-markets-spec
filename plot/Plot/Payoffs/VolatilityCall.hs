-- | Chart layouts for 'Payoffs.VolatilityCall'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Payoffs.VolatilityCall
  ( volatilityCallLayout
  , volatilityCallLayoutVsSqrtPrice
  , volatilityCallLayoutVsXi
  ) where

import Data.Colour
import Data.Colour.Names
import qualified Data.Vector as V
import Graphics.Rendering.Chart.Easy
import Liquidity.LiquidityGrid
  ( LadderResolution
  , XiX96(..)
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
import TickPath (TickPath(..))
import Volatility.TickVolatility
  ( RangeVolatility(..)
  , rangeAlongPath
  , unRangeVolatility
  )
import Volatility.VolatilityGrid (gammaCoordinate)
import Payoffs.VolatilityCall


volatilityCallLayoutAgainst
  :: String
  -> String
  -> (Int -> Tick -> Double)
  -> VolStrike
  -> Tick
  -> TickSpacing
  -> LadderResolution
  -> Layout Double Double
volatilityCallLayoutAgainst title xTitle xAt k iMin spacing iota
  | unLadderResolution iota < 2 =
      error "Payoffs.VolatilityCall.volatilityCallLayoutAgainst: ι must be ≥ 2"
  | otherwise = execEC $ do
    let
      book = bookPath iMin spacing iota
      ts = ticks book
      spots = rangeAlongPath book
      nSeg = V.length spots
      pts =
        [ ( xAt j (ts V.! j)
          , fromInteger (unRangeVolatility (payoff (spots V.! j) k))
          )
        | j <- [0 .. nSeg - 1]
        ]
    layout_title .= title
    layout_x_axis . laxis_title .= xTitle
    layout_y_axis . laxis_title .= "(S−K)+"
    setColors [opaque blue]
    plot $ line "VolatilityCall" [pts]

volatilityCallLayout
  :: VolStrike
  -> Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
volatilityCallLayout k xiWord eta spacing iMin iota =
  volatilityCallLayoutAgainst
    "π_σ (S−K)+ on gammaCoordinate"
    "uint256 gammaCoordinate"
    (\ _j t -> fromInteger (gammaCoordinate xiWord eta spacing t))
    k
    iMin
    spacing
    iota

volatilityCallLayoutVsSqrtPrice
  :: VolStrike
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
volatilityCallLayoutVsSqrtPrice k spacing iMin iota =
  volatilityCallLayoutAgainst
    "π_σ (S−K)+ on sqrtPriceX96"
    "sqrtPriceX96"
    (\ _j t -> toDouble (sqrtPriceX96 t))
    k
    iMin
    spacing
    iota

volatilityCallLayoutVsXi
  :: VolStrike
  -> XiX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
volatilityCallLayoutVsXi k xi spacing iMin iota =
  volatilityCallLayoutAgainst
    "π_σ (S−K)+ on xiCoordinate"
    "xiCoordinate (Q96)"
    (\ j _t -> fromInteger (unXiX96 (xiCoordinate xi j)))
    k
    iMin
    spacing
    iota

bookPath :: Tick -> TickSpacing -> LadderResolution -> TickPath
bookPath iMin spacing iota =
  let n = unLadderResolution iota
  in  TickPath n $
        V.generate n $ \x -> iMin + x * unTickSpacing spacing
