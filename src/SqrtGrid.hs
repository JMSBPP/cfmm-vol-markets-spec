{-# LANGUAGE PatternSynonyms #-}

module SqrtGrid
  ( Tick
  , SqrtPrice
  , SqrtPriceX96(..)
  , PayoffX96(..)
  , SqrtPlot(..)
  , pattern Q96
  , toDouble
  , payoffToDouble
  , sqrtPrice
  , sqrtPriceX96
  , tickGrid
  , sqrtPriceX96Grid
  , plotSqrtFunction
  , sqrtFunctionLayout
  , tickFromSqrtPriceX96
  , tickBase
  , TickSpacing
  , mkTickSpacing
  , unTickSpacing
  , mulX96
  , invX96
  , rpowX96
  , integerSqrt
  ) where

import Data.Colour
import Data.Colour.Names
import Graphics.Rendering.Chart.Backend.Cairo
import Graphics.Rendering.Chart.Easy



type Tick = Int
type SqrtPrice = Double
newtype SqrtPriceX96 = SqrtPriceX96 Integer deriving (Show, Eq, Ord)
newtype PayoffX96 = PayoffX96 Integer deriving (Show, Eq, Ord)

lambda :: Double
lambda = 1.0001

-- Protocol constant λ (Uniswap v3 tick base)
tickBase :: Double
tickBase = lambda

newtype TickSpacing = TickSpacing Int
  deriving (Show, Eq, Ord)

mkTickSpacing :: Int -> TickSpacing
mkTickSpacing d
  | d < 1 || d > 200 =
      error "SqrtGrid.mkTickSpacing: Δ_i must satisfy 1 ≤ Δ_i ≤ 200"
  | otherwise = TickSpacing d

unTickSpacing :: TickSpacing -> Int
unTickSpacing (TickSpacing d) = d

pattern Q96 :: Integer
pattern Q96 = 79228162514264337593543950336

-- Product of two Q96 words → Q96 (same rule as squareSqrtPrice).
mulX96 :: Integer -> Integer -> Integer
mulX96 a b = (a * b) `div` Q96

-- 1/a in Q96.
invX96 :: Integer -> Integer
invX96 a
  | a <= 0 = error "SqrtGrid.invX96: need a > 0"
  | otherwise = (Q96 * Q96) `div` a

-- a^n in Q96, n ≥ 0. a^0 = Q96 (the 1-word).
rpowX96 :: Integer -> Int -> Integer
rpowX96 _ n
  | n < 0 = error "SqrtGrid.rpowX96: n must be ≥ 0"
rpowX96 a n = go n a Q96
  where
    go 0 _ acc = acc
    go k base acc
      | odd k =
          go (k `div` 2) (mulX96 base base) (mulX96 acc base)
      | otherwise =
          go (k `div` 2) (mulX96 base base) acc

integerSqrt :: Integer -> Integer
integerSqrt n
  | n <= 0 = 0
  | otherwise = go (1 + n `div` 2)
  where
    go x =
      let x' = (x + n `div` x) `div` 2
      in  if x' >= x then x else go x'

-- Mathematical sqrt-price coordinate
sqrtPrice :: Tick -> SqrtPrice
sqrtPrice i = lambda ** (fromIntegral i / 2)

-- EVM / Uniswap fixed-point coordinate
sqrtPriceX96 :: Tick -> SqrtPriceX96
sqrtPriceX96 i = SqrtPriceX96 $ floor $ sqrtPrice i * fromIntegral Q96

tickGrid :: Int -> Tick -> Tick -> [Tick]
tickGrid spacing lo hi = [lo, lo + spacing .. hi]

sqrtPriceX96Grid :: Int -> Tick -> Tick  -> [SqrtPriceX96]
sqrtPriceX96Grid spacing lo hi = map sqrtPriceX96 $ tickGrid spacing lo hi

data SqrtPlot = SqrtPlot
  { plotTitle  :: String
  , xAxisTitle :: String
  , yAxisTitle :: String
  , xMin       :: SqrtPriceX96
  , xMax       :: SqrtPriceX96
  }



toDouble :: SqrtPriceX96 -> Double
toDouble (SqrtPriceX96 x) = fromIntegral x

payoffToDouble :: PayoffX96 -> Double
payoffToDouble (PayoffX96 x) = fromIntegral x



tickFromSqrtPriceX96 :: SqrtPriceX96 -> Tick
tickFromSqrtPriceX96 (SqrtPriceX96 p) =
  round $
    2 * log (fromInteger p / fromInteger Q96) / log lambda

sqrtFunctionEC
  :: SqrtPlot
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> EC (Layout Double Double) ()
sqrtFunctionEC config labeledFunctions = do
  let
    SqrtPriceX96 lowerBound = xMin config
    SqrtPriceX96 upperBound = xMax config

    numberOfSamples :: Integer
    numberOfSamples = 500

    sampleStep =
      max 1 ((upperBound - lowerBound) `div` numberOfSamples)

    sqrtPriceSamples =
      [ SqrtPriceX96 rawX96
      | rawX96 <-
          [ lowerBound
          , lowerBound + sampleStep
          .. upperBound
          ]
      ]

    functionPoints sqrtFunction =
      [ ( toDouble sample
        , max 0 (payoffToDouble (sqrtFunction sample))
        )
      | sample <- sqrtPriceSamples
      ]

  layout_title .= plotTitle config
  layout_x_axis . laxis_title .= xAxisTitle config
  layout_y_axis . laxis_title .= "PayoffX96"
  setColors [opaque blue, opaque red, opaque green, opaque orange]

  mapM_
    (\(seriesLabel, sqrtFunction) ->
      plot $
        line seriesLabel [functionPoints sqrtFunction]
    )
    labeledFunctions

sqrtFunctionLayout
  :: SqrtPlot
  -> [(String, SqrtPriceX96 -> PayoffX96)]
  -> Layout Double Double
sqrtFunctionLayout config labeledFunctions =
  execEC (sqrtFunctionEC config labeledFunctions)

plotSqrtFunction :: FilePath -> SqrtPlot -> [SqrtPriceX96 -> PayoffX96] -> IO ()
plotSqrtFunction output config sqrtFunctions =
  toFile def output $
    sqrtFunctionEC config
      [ ("", sqrtFunction)
      | sqrtFunction <- sqrtFunctions
      ]