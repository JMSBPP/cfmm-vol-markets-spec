module Payoffs.VolatilityCall
  ( VolStrike
  , mkVolStrike
  , unVolStrike
  , payoff
  , volatilityCall
  ) where

import qualified Data.Vector as V
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

