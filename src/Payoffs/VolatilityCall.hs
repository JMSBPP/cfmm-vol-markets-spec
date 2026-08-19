module Payoffs.VolatilityCall
  ( VolStrike
  , mkVolStrike
  , unVolStrike
  , payoff
  , volatilityCall
  , volatilityCallLayout
  ) where

import Data.Colour
import Data.Colour.Names
import qualified Data.Vector as V
import Graphics.Rendering.Chart.Easy
import Liquidity.LiquidityGrid
  ( LadderResolution
  , unLadderResolution
  )
import Pricing.PriceDeformation (EtaX96)
import SqrtGrid (Tick, TickSpacing, unTickSpacing)
import TickPath (TickPath(..))
import Volatility.TickVolatility
  ( RangeVolatility(..)
  , rangeAlongPath
  , unRangeVolatility
  )
import Volatility.VolatilityGrid (gammaCoordinate)

newtype VolStrike = VolStrike Integer
  deriving (Show, Eq)

mkVolStrike :: Integer -> VolStrike
mkVolStrike k
  | k < 0 =
      error "Payoffs.VolatilityCall.mkVolStrike: K must be >= 0"
  | otherwise = VolStrike k

unVolStrike :: VolStrike -> Integer
unVolStrike (VolStrike k) = k

payoff :: RangeVolatility -> VolStrike -> RangeVolatility
payoff (RangeVolatility s) (VolStrike k) =
  RangeVolatility (max (s - k) 0)

volatilityCall :: VolStrike -> (RangeVolatility -> RangeVolatility)
volatilityCall k s = payoff s k

-- Static book, same rungs as Liquidity vs-gamma. Not a CEV TickPath.
volatilityCallLayout
  :: VolStrike
  -> Integer
  -> EtaX96
  -> TickSpacing
  -> Tick
  -> LadderResolution
  -> Layout Double Double
volatilityCallLayout k xiWord eta spacing iMin iota
  | unLadderResolution iota < 2 =
      error "Payoffs.VolatilityCall.volatilityCallLayout: ι must be ≥ 2"
  | otherwise = execEC $ do
  let
    n = unLadderResolution iota
    book =
      TickPath n $
        V.generate n $ \x -> iMin + x * unTickSpacing spacing
    ts = ticks book
    spots = rangeAlongPath book
    nSeg = V.length spots
    pts =
      [ ( fromInteger (gammaCoordinate xiWord eta spacing (ts V.! j))
        , fromInteger (unRangeVolatility (payoff (spots V.! j) k))
        )
      | j <- [0 .. nSeg - 1]
      ]
  layout_title .= "π_σ (S−K)+ on gammaCoordinate"
  layout_x_axis . laxis_title .= "uint256 gammaCoordinate"
  layout_y_axis . laxis_title .= "(S−K)+"
  setColors [opaque blue]
  plot $ line "VolatilityCall" [pts]
