{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'TickPath'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.TickPath
  ( tickPathLayout
  ) where

import Control.Monad.ST (runST)
import Data.Colour
import Data.Colour.Names
import Data.Word (Word32)
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV
import qualified Data.Vector.Unboxed as VU
import Graphics.Rendering.Chart.Easy
import Pricing.PriceDeformation (uniswapMinTick)
import SqrtGrid
  ( Tick
  , SqrtPriceX96(..)
  , pattern Q96
  , sqrtPrice
  , tickFromSqrtPriceX96
  )
import System.Random.MWC (initialize)
import System.Random.MWC.Distributions (standard)
import Volatility.VolTermStructure
  ( Step(..)
  , VolTermStructure(..)
  , unInstantaneousVol
  )
import TickPath


tickPathLayout :: TickPath -> Layout Double Double
tickPathLayout path = execEC $ do
  let
    ys = V.toList (ticks path)
    pts =
      [ (fromIntegral t :: Double, fromIntegral i :: Double)
      | (t, i) <- zip [0 :: Int ..] ys
      ]
  layout_title .= "tick vs steps"
  layout_x_axis . laxis_title .= "steps"
  layout_y_axis . laxis_title .= "tick"
  setColors [opaque blue]
  plot $ line "TickPath" [pts]
