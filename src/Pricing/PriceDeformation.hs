{-# LANGUAGE PatternSynonyms #-}

module Pricing.PriceDeformation
  ( EtaX96(..)
  , VarSigmaX96(..)
  , pattern BASE_ETA
  , barSqrtPriceX96
  , uniswapMinTick
  , uniswapMaxTick
  , varSigma
  , deformTick
  , deformedSqrtPriceX96
  , plotDeformation
  , deformationLayout
  , plotVarSigmaEta
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

-- η · 2^96, with 0 < η < 1
newtype EtaX96 = EtaX96 Integer
  deriving (Show, Eq, Ord)

-- ς · 2^96, ς = η/(1-η) > 0
newtype VarSigmaX96 = VarSigmaX96 Integer
  deriving (Show, Eq, Ord)

-- Uniswap CPMM: η = 1/2, stored as 2^95
pattern BASE_ETA :: EtaX96
pattern BASE_ETA = EtaX96 39614081257132168796771975168

-- Tick 0: sqrt(P) = 1 in Q96
barSqrtPriceX96 :: SqrtPriceX96
barSqrtPriceX96 = SqrtPriceX96 Q96

uniswapMinTick :: Tick
uniswapMinTick = -887272

uniswapMaxTick :: Tick
uniswapMaxTick = 887272

-- ς_X96 = η_X96 * Q96 / (Q96 - η_X96)
varSigma :: EtaX96 -> VarSigmaX96
varSigma (EtaX96 eta)
  | eta <= 0 || eta >= Q96 =
      error "PriceDeformation.varSigma: η must satisfy 0 < η < 1"
  | otherwise =
      VarSigmaX96 $ (eta * Q96) `div` (Q96 - eta)

-- i' = floor(i * ς / 2^96); Nothing if i' is not a v3 tick
deformTick :: EtaX96 -> Tick -> Maybe Tick
deformTick eta i =
  let
    VarSigmaX96 varsigma = varSigma eta
    deformed =
      fromInteger $
        (toInteger i * varsigma) `div` Q96
  in
    if deformed < uniswapMinTick || deformed > uniswapMaxTick
      then Nothing
      else Just deformed

deformedSqrtPriceX96 :: EtaX96 -> Tick -> Maybe SqrtPriceX96
deformedSqrtPriceX96 eta i =
  sqrtPriceX96 <$> deformTick eta i

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
