{-# LANGUAGE PatternSynonyms #-}

-- | Chart layouts for 'Pricing.PriceDeformation'.  Split out of the pure module so that
-- consumers of the numeric core do not compile Chart/cairo.
module Plot.Pricing.PriceDeformation
  ( plotVarSigmaEta
  , deformationLayout
  , plotDeformation
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Backend.Cairo
import Graphics.Rendering.Chart.Easy
import SqrtGrid
  ( Tick
  , SqrtPriceX96(..)
  , pattern Q96
  , toDouble
  , sqrtPriceX96
  )
import Pricing.PriceDeformation


deformationEC
  :: String
  -> Tick
  -> Tick
  -> [EtaX96]
  -> EC (Layout Double Double) ()
deformationEC title tickLo tickHi etas = do
  let
    numberOfSamples = 500 :: Tick
    spanTicks = max 1 (tickHi - tickLo)
    step = max 1 (spanTicks `div` numberOfSamples)
    ticks = [tickLo, tickLo + step .. tickHi]

    deformedPoints eta =
      [ (toDouble (sqrtPriceX96 i), toDouble p)
      | i <- ticks
      , Just p <- [deformedSqrtPriceX96 eta i]
      ]

    otherEtas = filter (/= BASE_ETA) etas

  layout_title .= title
  layout_x_axis . laxis_title .= "sqrtPriceX96"
  layout_y_axis . laxis_title .= "sqrtPriceX96"
  setColors [opaque blue, opaque red, opaque green]

  plot $ line "η = 1/2" [deformedPoints BASE_ETA]
  mapM_
    (\eta -> plot $ line "η = 2/3" [deformedPoints eta])
    otherEtas

deformationLayout
  :: String
  -> Tick
  -> Tick
  -> [EtaX96]
  -> Layout Double Double
deformationLayout title tickLo tickHi etas =
  execEC (deformationEC title tickLo tickHi etas)

plotDeformation
  :: FilePath
  -> String
  -> Tick
  -> Tick
  -> [EtaX96]
  -> IO ()
plotDeformation output title tickLo tickHi etas =
  toFile def output (deformationEC title tickLo tickHi etas)

plotVarSigmaEta :: FilePath -> IO ()
plotVarSigmaEta output = do
  let
    numberOfSamples = 500 :: Integer
    -- (0, 2^96), exclusive of the poles
    lower = 1
    upper = Q96 - 1
    step = max 1 ((upper - lower) `div` numberOfSamples)
    etas =
      [ EtaX96 raw
      | raw <- [lower, lower + step .. upper]
      , raw < Q96
      ]

    curvePoints =
      [ (fromInteger etaRaw :: Double, fromInteger varsigmaRaw :: Double)
      | e@(EtaX96 etaRaw) <- etas
      , let VarSigmaX96 varsigmaRaw = varSigma e
      ]

  toFile def output $ do
    layout_title .= "ς(η) = η/(1-η)"
    layout_x_axis . laxis_title .= "EtaX96"
    layout_y_axis . laxis_title .= "VarSigmaX96"
    setColors [opaque blue]
    plot $ line "ς(η)" [curvePoints]
