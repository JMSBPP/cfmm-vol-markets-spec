{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Control.Exception (ErrorCall, evaluate, try)

import Greeks.Gamma (Gamma(..), cpmmGamma)
import Graphics.Rendering.Chart.Easy (execEC, layout_title, (.=))
import PlotUtils (Panel(..), canvasSize)
import OptionRatio (OptionRatio(..))
import Payoffs.Payoff (squareSqrtPrice)
import qualified Payoffs.Payoff as Payoff
import Payoffs.NId
  ( MintPlan(..)
  , PanopticTokenId(..)
  , fourLegNumLegs
  , fourLegSkeleton
  , mkNId
  , nSigma
  , panopticIsLong
  , panopticOptionRatio
  , panopticStrike
  , panopticTickSpacing
  , panopticTokenType
  , panopticWidth
  , scaleByNId
  , unNId
  )
import Payoffs.Forward
  ( AtmForward(..)
  , forward
  , nakedForwardQ96
  )
import qualified Payoffs.Forward as Fwd
import Payoffs.Log (logContract, nakedLogQ96)
import qualified Payoffs.Log as PLog
import Payoffs.VariancePortfolio
  ( fromDef6
  , fromLegs
  , scaleByTargetVega
  , toPayoff
  )
import Payoffs.TargetVega
  ( mkTargetVega
  , positionSizeForTargetVega
  , targetVegaFromMint
  , targetVegaFromMints
  , unTargetVega
  )
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
import Volatility.CevField
  ( cevLayoutVsGamma
  , cevLayoutVsSqrtPrice
  , cevLayoutVsXi
  )
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
  , sqrtPrice
  , sqrtPriceX96
  , tickBase
  , tickFromSqrtPriceX96
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
  , volatilityCallLayoutVsSqrtPrice
  , volatilityCallLayoutVsXi
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

  assertThrows "mkNId 1 rejected" (mkNId 1)
  assertThrows "mkNId 3 rejected" (mkNId 3)
  assertEqual "mkNId 32 stores N" 32 (unNId (mkNId 32))
  assertEqual "N_σ = N/2" 16 (nSigma (mkNId 32))
  assertEqual "N_id * N_σ on 1-word: scaleByNId N (N_σ) = 1"
    1
    (scaleByNId (mkNId 32) (nSigma (mkNId 32)))
  assertEqual "scaleByNId 2/32 of 32 = 2" 2 (scaleByNId (mkNId 32) 32)

  let
    n32 = mkNId 32
    atm0 = AtmForward (sqrtPriceX96 0)
    PayoffX96 p0 = squareSqrtPrice (sqrtPriceX96 0)
    PayoffX96 naked0 = nakedForwardQ96 (sqrtPriceX96 0) atm0
  assertEqual "forward naked at p* is 0" 0 naked0
  assertEqual "squareSqrtPrice tick0 is Q96" Q96 p0
  let
    s10 = sqrtPriceX96 10
    SqrtPriceX96 s10Raw = s10
    SqrtPriceX96 s0Raw = sqrtPriceX96 0
    PayoffX96 naked10 = nakedForwardQ96 s10 atm0
    PayoffX96 p10 = squareSqrtPrice s10
    expectedNaked =
      ((p10 - p0) * Q96) `div` p0
  assertEqual "naked forward is (P-P*)/P* in Q96" expectedNaked naked10
  if naked10 == (s10Raw - s0Raw)
    then error "forward must not be s-s*"
    else putStrLn "ok: forward ≠ s−s*"
  assertEqual
    "optional forward = N_id * naked"
    (scaleByNId n32 naked10)
    (let PayoffX96 y = Fwd.payoff n32 s10 atm0 in y)
  _ <- evaluate (forward n32 atm0)
  putStrLn "ok: forward Payoff"

  let
    PayoffX96 log0 = nakedLogQ96 (sqrtPriceX96 0) atm0
  assertEqual "log at p* is 0" 0 log0
  let
    i10 = tickFromSqrtPriceX96 s10
    i0 = tickFromSqrtPriceX96 (sqrtPriceX96 0)
    expectedLog =
      floor (fromIntegral Q96 * fromIntegral (i10 - i0) * log tickBase)
    PayoffX96 log10 = nakedLogQ96 s10 atm0
  assertEqual "naked log is (i-i*) ln λ in Q96" expectedLog log10
  let SqrtPriceX96 word10 = s10
  if log10 == word10
    then error "log must not be ln of the Q96 word"
    else putStrLn "ok: log ≠ Q96 word"
  assertEqual
    "optional log = N_id * naked"
    (scaleByNId n32 log10)
    (let PayoffX96 y = PLog.payoff n32 s10 atm0 in y)
  _ <- evaluate (logContract n32 atm0)
  putStrLn "ok: logContract Payoff"

  let
    remaining = PayoffX96 1000
    piLegs = fromLegs n32 atm0 remaining
    piDef6 = fromDef6 n32 atm0 remaining
    yLegs0 = Payoff.runPayoff (toPayoff piLegs) (sqrtPriceX96 0)
    yDef0 = Payoff.runPayoff (toPayoff piDef6) (sqrtPriceX96 0)
  assertEqual "fromLegs at ATM = remaining" remaining yLegs0
  assertEqual "fromDef6 at ATM = remaining" remaining yDef0
  assertEqual "fromLegs = fromDef6 at ATM" yLegs0 yDef0
  let
    yLegs10 = Payoff.runPayoff (toPayoff piLegs) s10
    yDef10 = Payoff.runPayoff (toPayoff piDef6) s10
  assertEqual "fromLegs = fromDef6 off ATM" yLegs10 yDef10

  assertThrows "mkTargetVega 0 rejected" (mkTargetVega 0)
  assertThrows "mkTargetVega (-1) rejected" (mkTargetVega (-1))
  assertEqual "mkTargetVega 1" 1 (unTargetVega (mkTargetVega 1))
  let
    unit = scaleByTargetVega (mkTargetVega 1) piLegs
    times3 = scaleByTargetVega (mkTargetVega 3) piLegs
    PayoffX96 u10 = Payoff.runPayoff unit s10
    PayoffX96 t10 = Payoff.runPayoff times3 s10
    PayoffX96 base10 = Payoff.runPayoff (toPayoff piLegs) s10
  assertEqual "ΔQ_v=1 recovers Π_opt" base10 u10
  assertEqual "ΔQ_v=3 scales Y by 3" (3 * base10) t10

  let
    dqv7 = mkTargetVega 7
    ratios = (1, 2, 3, 4)
    skeleton = fourLegSkeleton 0 ratios
  assertThrows "optionRatio 0 rejected" (fourLegSkeleton 0 (0, 1, 1, 1))
  assertThrows "optionRatio 128 rejected" (fourLegSkeleton 0 (1, 1, 1, 128))
  assertEqual "num_legs=4" 4 (fourLegNumLegs skeleton)
  assertEqual "tickSpacing once" 10 (panopticTickSpacing skeleton)
  assertEqual "optionRatio leg 0" 1 (panopticOptionRatio skeleton 0)
  assertEqual "optionRatio leg 1" 2 (panopticOptionRatio skeleton 1)
  assertEqual "optionRatio leg 2" 3 (panopticOptionRatio skeleton 2)
  assertEqual "optionRatio leg 3" 4 (panopticOptionRatio skeleton 3)
  if panopticOptionRatio skeleton 0 == panopticOptionRatio skeleton 1
       && panopticOptionRatio skeleton 1 == panopticOptionRatio skeleton 2
       && panopticOptionRatio skeleton 2 == panopticOptionRatio skeleton 3
    then error "optionRatio must differ per leg in this inhabitant"
    else putStrLn "ok: optionRatio differs per leg"
  mapM_
    (\leg -> do
      assertEqual ("isLong leg " ++ show leg) 1 (panopticIsLong skeleton leg)
      assertEqual ("width leg " ++ show leg) 1 (panopticWidth skeleton leg)
    )
    [0, 1, 2, 3]
  assertEqual "tokenType put 0" 0 (panopticTokenType skeleton 0)
  assertEqual "tokenType put 1" 0 (panopticTokenType skeleton 1)
  assertEqual "tokenType call 2" 1 (panopticTokenType skeleton 2)
  assertEqual "tokenType call 3" 1 (panopticTokenType skeleton 3)
  assertEqual "strike leg 0" (-15) (panopticStrike skeleton 0)
  assertEqual "strike leg 1" (-5) (panopticStrike skeleton 1)
  assertEqual "strike leg 2" 5 (panopticStrike skeleton 2)
  assertEqual "strike leg 3" 15 (panopticStrike skeleton 3)
  let
    plan7 = MintPlan skeleton (positionSizeForTargetVega dqv7)
  assertEqual
    "round-trip positionSize = ΔQ_v*"
    dqv7
    (targetVegaFromMint plan7)
  let
    fromA = scaleByTargetVega dqv7 piLegs
    fromB = scaleByTargetVega (targetVegaFromMint plan7) piLegs
    yA0 = Payoff.runPayoff fromA (sqrtPriceX96 0)
    yB0 = Payoff.runPayoff fromB (sqrtPriceX96 0)
    yA10 = Payoff.runPayoff fromA s10
    yB10 = Payoff.runPayoff fromB s10
  assertEqual "hop B ATM Y = hop A" yA0 yB0
  assertEqual "hop B off-ATM Y = hop A" yA10 yB10
  assertThrows
    "num_legs≠4 rejected"
    (targetVegaFromMint (MintPlan (PanopticTokenId 0 3) 1))

  assertThrows "empty mint list rejected" (targetVegaFromMints [])
  let
    p1 = MintPlan skeleton (positionSizeForTargetVega (mkTargetVega 4))
    p2 = MintPlan skeleton (positionSizeForTargetVega (mkTargetVega 5))
  assertEqual
    "ΔQ_v* additive"
    (mkTargetVega 9)
    (targetVegaFromMints [p1, p2])

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
  let
    sig10 = unInstantaneousVol (volAt vts 10 (Step 0))
  approxEqual
    "CEV hyperbola: volAt(10) = δ / p_{1/2}(10)"
    1e-9
    (1.0 / sqrtPrice 10)
    sig10
  approxEqual
    "CEV hyperbola: σ(i)·p_{1/2}(i) = δ"
    1e-9
    1.0
    (sig10 * sqrtPrice 10)
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
  assertEqual
    "static book last segment n=8 Δ=10 ⇒ S=(Δ·7/2)²"
    (RangeVolatility 1225)
    (bookRanges V.! 6)

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
  assertEqual
    "ξ^0 = Q96"
    Q96
    (unXiX96 (xiCoordinate xiPinned 0))
  if unXiX96 (xiCoordinate xiPinned 0) > unXiX96 (xiCoordinate xiPinned 1)
    then putStrLn "ok: ξ^x decreasing for ξ*<1"
    else
      error
        "xiCoordinate must decrease in rung for ξ*<1 (vs-xi π_σ is a decreasing curve)"
  _ <- evaluate
    (volatilityCallLayoutVsSqrtPrice
      (mkVolStrike 0)
      spacing10
      (0 :: Tick)
      (mkLadderResolution 32)
    )
  _ <- evaluate
    (volatilityCallLayoutVsXi
      (mkVolStrike 0)
      xiPinned
      spacing10
      (0 :: Tick)
      (mkLadderResolution 32)
    )
  putStrLn "ok: π_σ vs-sqrtPrice / vs-xi layouts"
  _ <- evaluate
    (cevLayoutVsSqrtPrice vts spacing10 (0 :: Tick) (mkLadderResolution 32))
  _ <- evaluate
    (cevLayoutVsGamma
      vts
      (unXiX96 xiPinned)
      BASE_ETA
      spacing10
      (0 :: Tick)
      (mkLadderResolution 32)
    )
  _ <- evaluate
    (cevLayoutVsXi
      vts
      xiPinned
      spacing10
      (0 :: Tick)
      (mkLadderResolution 32)
    )
  putStrLn "ok: CEV vs-{sqrtPrice,gamma,xi} layouts"
  let
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
