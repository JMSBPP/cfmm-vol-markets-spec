{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Control.Exception (ErrorCall, evaluate, try)

import Greeks.Gamma (Gamma(..), cpmmGamma)
import Graphics.Rendering.Chart.Easy (execEC, layout_title, (.=))
import PlotUtils (Panel(..), canvasSize)
import OptionRatio (OptionRatio(..))
import Payoffs.Payoff (squareSqrtPrice)
import Liquidity.LiquidityGrid
  ( XiX96(..)
  , ell
  , mkLadderResolution
  , mkXiX96
  , unLiquidityDensityX96
  , unXiX96
  , xiCoordinate
  , xiStar
  )
import Pricing.PriceDeformation (EtaX96(..), pattern BASE_ETA)
import Volatility.VolTermStructure
  ( BarL(..)
  , FlowVol(..)
  , Step(..)
  , cevDeltaCpmm
  , cevFromPhi
  , unInstantaneousVol
  , volAt
  )
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , Tick
  , invX96
  , mkTickSpacing
  , pattern Q96
  , rpowX96
  , sqrtPriceX96
  , unTickSpacing
  )
import State (pattern SQRT_PRICE_1_4, pattern SQRT_PRICE_4_1)
import StrikeX96 (StrikeX96(..))
import Data.Vector ((!))
import qualified Data.Vector as V
import TickPath (TickPath(..), mkTickPath)
import Payoffs.VolatilityCall
  ( mkVolStrike
  , payoff
  , unVolStrike
  , volatilityCall
  )
import Volatility.TickVolatility
  ( RangeVolatility(..)
  , VolatilityAverage(..)
  , averageVolatility
  , rangeAlongPath
  , volatilityOnRange
  )
import Volatility.VolatilityGrid (gammaCoordinate)

assertThrows :: forall a. String -> a -> IO ()
assertThrows label value = do
  result <- try (evaluate value) :: IO (Either ErrorCall a)
  case result of
    Left _  -> putStrLn ("ok: " ++ label)
    Right _ -> error (label ++ ": expected error")

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual =
  if expected == actual
    then putStrLn ("ok: " ++ label)
    else error (label ++ ": expected " ++ show expected ++ " but got " ++ show actual)

approxEqual :: String -> Double -> Double -> Double -> IO ()
approxEqual label tol expected actual =
  if abs (expected - actual) <= tol
    then putStrLn ("ok: " ++ label)
    else
      error
        ( label
            ++ ": expected "
            ++ show expected
            ++ " but got "
            ++ show actual
        )

main :: IO ()
main = do
  let dummy = execEC (layout_title .= "")
  assertEqual
    "canvasSize Cell is 1×1"
    (900, 720)
    (canvasSize (Cell dummy))
  assertEqual
    "canvasSize Beside is 1×2"
    (1800, 720)
    (canvasSize (Beside (Cell dummy) (Cell dummy)))
  assertEqual
    "canvasSize Above is 2×1"
    (900, 1440)
    (canvasSize (Above (Cell dummy) (Cell dummy)))
  assertEqual
    "canvasSize 2×2 with Vacant"
    (1800, 1440)
    (canvasSize
      (Above
        (Beside (Cell dummy) (Cell dummy))
        (Beside (Cell dummy) Vacant)
      )
    )

  let
    barL2 = BarL 2
    flowVol1 = FlowVol 1
    etaTwoThirds = EtaX96 $ (2 * Q96) `div` 3
  approxEqual
    "cevDeltaCpmm BASE_ETA BarL=2 FlowVol=1 ⇒ δ=1"
    1e-12
    1.0
    (cevDeltaCpmm barL2 flowVol1)
  let
    vts = cevFromPhi BASE_ETA barL2 flowVol1
    sig0 = unInstantaneousVol (volAt vts 0 (Step 0))
  approxEqual
    "volAt tick 0 ⇒ σ=1"
    1e-9
    1.0
    sig0
  assertThrows "BarL 0 rejected" (cevFromPhi BASE_ETA (BarL 0) flowVol1)
  assertThrows "FlowVol 0 rejected" (cevFromPhi BASE_ETA barL2 (FlowVol 0))
  assertThrows "η ≠ BASE_ETA rejected" (cevFromPhi etaTwoThirds barL2 flowVol1)

  assertThrows
    "mkTickPath N=1 rejected"
    (mkTickPath 1 vts 1 0)
  let
    path32 = mkTickPath 32 vts 42 0
  assertEqual "path length 32" 32 (pathLength path32)
  assertEqual "path length field matches vector" 32 (V.length (ticks path32))
  assertEqual "ticks[0] = i0" 0 (ticks path32 ! 0)
  let
    pathAgain = mkTickPath 32 vts 42 0
  assertEqual
    "same seed ⇒ same path"
    (ticks path32)
    (ticks pathAgain)

  let
    constantPath =
      TickPath 8 (V.replicate 8 0)
  assertEqual
    "constant path ⇒ σ_X = 0"
    (VolatilityAverage 0)
    (averageVolatility constantPath)
  assertEqual
    "volatilityOnRange identical ticks"
    0
    (volatilityOnRange 1 5 5 5 5)
  assertEqual
    "rangeAlongPath length N-1"
    31
    (V.length (rangeAlongPath path32))
  let
    constantRanges = rangeAlongPath constantPath
  assertEqual
    "constant path ⇒ rangeAlongPath all 0"
    (V.replicate 7 (RangeVolatility 0))
    constantRanges

  let
    bookPath = TickPath 8 (V.generate 8 (\x -> x * 10))
    bookRanges = rangeAlongPath bookPath
  assertEqual
    "static book first segment Δ=10"
    (RangeVolatility 25)
    (bookRanges V.! 0)

  assertThrows "mkVolStrike (-1) rejected" (mkVolStrike (-1))
  assertEqual "mkVolStrike 0" 0 (unVolStrike (mkVolStrike 0))
  assertEqual "mkVolStrike 3" 3 (unVolStrike (mkVolStrike 3))
  assertEqual
    "payoff ITM"
    (RangeVolatility 2)
    (payoff (RangeVolatility 5) (mkVolStrike 3))
  assertEqual
    "payoff OTM"
    (RangeVolatility 0)
    (payoff (RangeVolatility 2) (mkVolStrike 3))
  assertEqual
    "payoff ATM"
    (RangeVolatility 0)
    (payoff (RangeVolatility 3) (mkVolStrike 3))
  assertEqual
    "constant path, K=0 ⇒ call 0"
    (RangeVolatility 0)
    (payoff (constantRanges V.! 0) (mkVolStrike 0))
  assertEqual
    "volatilityCall is payoff flipped"
    (RangeVolatility 2)
    (volatilityCall (mkVolStrike 3) (RangeVolatility 5))

  assertThrows "TickSpacing 0 rejected" (mkTickSpacing 0)
  assertThrows "TickSpacing 201 rejected" (mkTickSpacing 201)
  assertEqual "TickSpacing 1" 1 (unTickSpacing (mkTickSpacing 1))
  assertEqual "TickSpacing 200" 200 (unTickSpacing (mkTickSpacing 200))

  let
    spacing10 = mkTickSpacing 10
    XiX96 xiStar10 = xiStar spacing10
    SqrtPriceX96 s10 = sqrtPriceX96 10
    expectedXiStar10 = invX96 s10
  assertEqual "xiStar Δ_i=10" expectedXiStar10 xiStar10
  assertThrows "ξ = 1 rejected" (mkXiX96 Q96)

  let
    xiHalf = mkXiX96 (Q96 `div` 2)
    expectedCoord = Q96 `div` 4
  assertEqual
    "xiCoordinate (1/2)^2"
    expectedCoord
    (unXiX96 (xiCoordinate xiHalf 2))

  assertThrows "ι = 0 rejected" (mkLadderResolution 0)

  let
    iota4 = mkLadderResolution 4
    densities =
      [ unLiquidityDensityX96 (ell xiHalf iota4 x)
      | x <- [0, 1, 2, 3]
      ]
    densitySum = sum densities
  if abs (densitySum - Q96) > 4
    then
      error
        ("ell partition: sum " ++ show densitySum ++ " vs Q96")
    else putStrLn "ok: ell sums to Q96 (tol 4)"

  assertEqual
    "ell single rung"
    Q96
    (unLiquidityDensityX96 (ell xiHalf (mkLadderResolution 1) 0))

  let
    xiPinned = xiStar spacing10
    eta = BASE_ETA
    i0 = 0 :: Tick
    i1 = 10 :: Tick
    g0 = gammaCoordinate (unXiX96 xiPinned) eta spacing10 i0
    g1 = gammaCoordinate (unXiX96 xiPinned) eta spacing10 i1
    ratioWord = rpowX96 (invX96 (unXiX96 xiPinned)) 15
    left = g1 * Q96
    right = g0 * ratioWord
  -- integerSqrt on the ½-exponent (η=1/2) leaves ULP; relative check, not Double **.
  if abs (left - right) > max 1 (right `div` (10 ^ (12 :: Int)))
    then
      error
        ( "gammaCoordinate ratio Theorem 38: "
            ++ show left
            ++ " vs "
            ++ show right
        )
    else putStrLn "ok: gammaCoordinate ratio Theorem 38"

  _ <- evaluate (gammaCoordinate (unXiX96 xiPinned) eta spacing10 (-10 :: Tick))
  putStrLn "ok: gammaCoordinate negative tick"

  let
    gK0 = runGamma (cpmmGamma (StrikeX96 Q96) (OptionRatio 4.0)) (sqrtPriceX96 0)
    gK10 = runGamma (cpmmGamma (StrikeX96 Q96) (OptionRatio 4.0)) (sqrtPriceX96 10)
    x0 = gammaCoordinate (unXiX96 xiPinned) eta spacing10 (0 :: Tick)
    x10 = gammaCoordinate (unXiX96 xiPinned) eta spacing10 (10 :: Tick)
    slope0 = negate (fromRational gK0) / fromInteger x0
    slope10 = negate (fromRational gK10) / fromInteger x10
  if gK0 == 0 || gK10 == 0
    then error "expected interior Γ at ticks 0 and 10"
    else
      approxEqual
        "interior −Γ / Γ_φ is constant"
        1e-6
        slope0
        slope10

  let
    strikeAtm = StrikeX96 Q96
    r = OptionRatio 4.0
    gamma = runGamma (cpmmGamma strikeAtm r)
    PayoffX96 kPrice = squareSqrtPrice (SqrtPriceX96 Q96)

  assertEqual "boundary p = k/r ⇒ Γ = 0" 0 (gamma SQRT_PRICE_1_4)
  assertEqual "boundary p = kr ⇒ Γ = 0" 0 (gamma SQRT_PRICE_4_1)
  approxEqual
    "ATM Γ = −1/(3K) for r = 4"
    1e-40
    ((-1) / (3 * fromInteger Q96))
    (fromRational (gamma (SqrtPriceX96 Q96)))

  -- Interior is strictly negative; the plot uses −Γ.
  let interior = gamma (SqrtPriceX96 Q96)
  if interior >= 0
    then error "ATM Γ must be negative"
    else putStrLn "ok: interior Γ < 0 (plot −Γ)"

  -- Spot well below the range.
  assertEqual "below range Γ = 0" 0 (gamma (SqrtPriceX96 (Q96 `div` 4)))

  -- Sanity vs (3.24) at a second interior point.
  let
    pMid = SqrtPriceX96 (Q96 + Q96 `div` 8)
    PayoffX96 pPrice = squareSqrtPrice pMid
    formula =
      (-0.5)
        * sqrt (4.0 * fromInteger kPrice)
        / (3.0 * (fromInteger pPrice ** 1.5))
  approxEqual
    "interior matches (3.24)"
    1e-30
    formula
    (fromRational (gamma pMid))
