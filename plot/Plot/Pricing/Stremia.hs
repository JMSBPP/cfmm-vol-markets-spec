{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Pricing.Stremia'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Pricing.Stremia
  ( plotFeeVsReturn
  , plotFeeRateVsSqrt
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Backend.Cairo
import Graphics.Rendering.Chart.Easy
import qualified Payoffs.Payoff as Payoff
import Payoffs.Linear (linearPayoff)
import Payoffs.Return (mkReturn, unReturnPips)
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , integerSqrt
  , invX96
  , mulX96
  , pattern Q96
  , toDouble
  )
import Pricing.Stremia


plotFeeVsReturn :: FilePath -> SqrtPriceX96 -> [FeePips] -> IO ()
plotFeeVsReturn path mid fees =
  let
    pMid = linearPayoff mid
    askPts =
      [ ( fromIntegral (unFeePips φ) :: Double
        , fromIntegral (unReturnPips (mkReturn (nakedAskQ96 φ mid) pMid)) :: Double
        )
      | φ <- fees
      ]
    bidPts =
      [ ( fromIntegral (unFeePips φ) :: Double
        , fromIntegral (unReturnPips (mkReturn (nakedBidQ96 φ mid) pMid)) :: Double
        )
      | φ <- fees
      ]
    idPts =
      [ let x = fromIntegral (unFeePips φ) :: Double
        in  (x, x)
      | φ <- fees
      ]
  in
    toFile def path $ do
      layout_title .= "FeePips vs ReturnPips (ask / bid / r = φ)"
      layout_x_axis . laxis_title .= "FeePips"
      layout_y_axis . laxis_title .= "ReturnPips"
      setColors [opaque red, opaque blue, opaque green]
      plot $ line "ask" [askPts]
      plot $ line "bid" [bidPts]
      plot $ line "r = φ" [idPts]

plotFeeRateVsSqrt :: FilePath -> SqrtPriceX96 -> [FeePips] -> IO ()
plotFeeRateVsSqrt path mid@(SqrtPriceX96 sMid) fees =
  let
    askSqrt φ =
      let sf = sqrtFeeFactorX96 (feeFactor φ)
      in  SqrtPriceX96 (mulX96 sMid sf)
    bidSqrt φ =
      let sf = sqrtFeeFactorX96 (feeFactor φ)
      in  SqrtPriceX96 (mulX96 sMid (invX96 sf))
    askPts =
      [ ( toDouble (askSqrt φ)
        , fromIntegral (unFeePips φ) :: Double
        )
      | φ <- fees
      ]
    bidPts =
      [ ( toDouble (bidSqrt φ)
        , fromIntegral (unFeePips φ) :: Double
        )
      | φ <- fees
      ]
    midMark =
      [ (toDouble mid, 0.0 :: Double)
      , (toDouble mid, fromIntegral (unFeePips (last fees)) :: Double)
      ]
  in
    toFile def path $ do
      layout_title .= "Fee rate vs quote SqrtPriceX96 (bid left / ask right of mid)"
      layout_x_axis . laxis_title .= "SqrtPriceX96"
      layout_y_axis . laxis_title .= "FeePips"
      setColors [opaque red, opaque blue, opaque gray]
      plot $ line "ask" [askPts]
      plot $ line "bid" [bidPts]
      plot $ line "mid" [midMark]
