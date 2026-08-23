{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Control.Exception (ErrorCall, evaluate, try)

import Greeks.Gamma (Gamma(..), cpmmGamma)
import Graphics.Rendering.Chart.Easy (execEC, layout_title, (.=))
import Plotting.PlotUtils (Panel(..), canvasSize)
import OptionRatio (OptionRatio(..))
import Payoffs.Payoff (squareSqrtPrice)
import qualified Payoffs.Payoff as Payoff
import Payoffs.Linear (linearPayoff)
import Payoffs.Return
  ( mkReturn
  , returnPipsScale
  , unReturnPips
  )
import Panoptic.NId
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
  , volOrderToMintPlan
  , volOrderToTokenId
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
  , variancePortfolioLayoutVsGamma
  , variancePortfolioLayoutVsXi
  )
import TargetVega
  ( mkTargetVega
  , positionSizeForTargetVega
  , targetVegaFromMint
  , targetVegaFromMints
  , unTargetVega
  )
import Liquidity.LiquidityChunk
  ( chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  , createChunk
  , unLiquidityChunk
  )
import Liquidity.TickLiquidity
  ( TickLiquidity(..)
  , tickLiquidityAt
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
import Pricing.PriceDeformation
  ( EtaX96(..)
  , pattern BASE_ETA
  , uniswapMaxTick
  )
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
import Pricing.Stremia
  ( FeeFactorX96(..)
  , FeePips(..)
  , askPayoff
  , bidPayoff
  , compositeFeePips
  , feeFactor
  , feePipsFromAsk
  , feePipsFromBid
  , feePipsFromBidAsk
  , feePipsScale
  , mkFeePips
  , nakedAskQ96
  , nakedBidQ96
  , sqrtFeeFactorX96
  , unFeeFactorX96
  , unFeePips
  )
import Pricing.FeeStructure
  ( FeeStructure(..)
  , mkFeeStructure
  , toFeePips
  )
import Pricing.MarkUpStructure
  ( MarkUpStructure(foldMarkUpFactor, markUpFactors)
  , TwoSidedMarkUp(markupPhiX, markupPhiM)
  )
import Pricing.ExpectedReturn
  ( ExpectedReturn(..)
  , ReturnFromKappa(..)
  , unExpectedReturn
  )
import Pricing.InterestPriceMap
  ( mkInterestPriceMap
  , priceTickAt
  )
import Payoffs.Savings (savings, savingsPayoff)
import Payoffs.Swap
  ( Leg(..)
  , Swap(..)
  , expectedReturnWeightX96
  , runSwapAlongTenor
  , runSwapAlongTenorMixture
  , scalePayoffX96
  , survivalFactorX96
  , swapFromFeeStructure
  , swapParameterized
  )
import Payoffs.TransactionalFeeCapture
  ( TransactionalFeeCapture(..)
  , assertAccountingIdentityWithSwap
  , feeFactorX96
  , feeRevenueExpectedReturn
  , payPartitionErrorX96
  , recvPartitionErrorX96
  , runFeeCaptureAlongTenor
  , runFeeCaptureAlongTenorMixture
  , transactionalFeeCaptureFromFeeStructure
  )
import Pricing.InterestSqrt
  ( InterestSqrtX96(..)
  , interestSqrtX96
  , mkInterestTick
  , unInterestSqrtX96
  , unInterestTick
  )
import Trading.PriceImpact
  ( askSqrtPriceX96
  , bidSqrtPriceX96
  )
import Trading.Quote
  ( mkQuote
  , phiMFromQuote
  , phiXFromQuote
  )
import Trading.KappaCoordinate
  ( KappaCoordinate(..)
  , KappaTick(..)
  , defaultKappaSpacing
  , kappaAt
  , kappaFromTick
  , mkKappaSpacing
  , mkKappaTick
  , snapKappaTick
  , unKappaSpacing
  , unKappaTick
  )
import SqrtGrid
  ( PayoffX96(..)
  , SqrtPriceX96(..)
  , Tick
  , integerSqrt
  , invX96
  , mkTickSpacing
  , mulX96
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
import qualified Payoffs.CLMMPosition as CLMM
import Payoffs.ChunkPrincipal (chunkPrincipal, chunkAmount0, unitChunk)
import Data.Vector ((!))
import qualified Data.Vector as V
import TickPath (TickPath(..), mkTickPath, pathLength, ticks)
import Payoffs.VolatilityCall
  ( mkVolStrike
  , payoff
  , unVolStrike
  , volatilityCall
  , volatilityCallLayoutVsSqrtPrice
  , volatilityCallLayoutVsXi
  )
import Volatility.VolOrder
  ( fixtureSymmetricVolOrder
  , legIntervals
  , mkVolOrder
  , mkVolRangeWidth
  , mkVolSkew
  , roundTick
  , tickBucketFromVolOrder
  , tickVolatilityTick
  , volOrderSplitPoints
  )
import Volatility.TickVolatility
  ( RangeVolatility(..)
  , VolatilityAverage(..)
  , averageVolatility
  , rangeAlongPath
  , unVolatilityAverage
  , volatilityOnRange
  )
import Volatility.ExpectedVolatility
  ( ExpectedVolatility(..)
  , expectedVolatilityUniformTenor
  , expectedVolatilityWindowStub
  , realizedVolatilityFromAverage
  , tenorTickPath
  , unExpectedVolatility
  , unRealizedVolatility
  , unVolGap
  , volGap
  )
import Volatility.ImpliedVolatility (impliedVolatilityFromAverage)
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
    plan7 =
      MintPlan
        skeleton
        (createChunk (-20) 20 (positionSizeForTargetVega dqv7))
  assertEqual
    "round-trip chunkLiquidity = ΔQ_v*"
    dqv7
    (targetVegaFromMint plan7)
  assertEqual "envelope lo" (-20) (chunkTickLower (mintChunk plan7))
  assertEqual "envelope hi" 20 (chunkTickUpper (mintChunk plan7))
  let
    fromA = scaleByTargetVega dqv7 piLegs
    fromB = scaleByTargetVega (targetVegaFromMint plan7) piLegs
    yA0 = Payoff.runPayoff fromA (sqrtPriceX96 0)
    yB0 = Payoff.runPayoff fromB (sqrtPriceX96 0)
    yA10 = Payoff.runPayoff fromA s10
    yB10 = Payoff.runPayoff fromB s10
  assertEqual "hop B ATM Y = hop A" yA0 yB0
  assertEqual "hop B off-ATM Y = hop A" yA10 yB10
  let
    piZero = fromLegs n32 atm0 (PayoffX96 0)
    hopBZero = scaleByTargetVega (targetVegaFromMint plan7) piZero
    yAtm = Payoff.runPayoff hopBZero (sqrtPriceX96 0)
    PayoffX96 yLeft = Payoff.runPayoff hopBZero (sqrtPriceX96 (-160))
    PayoffX96 yRight = Payoff.runPayoff hopBZero (sqrtPriceX96 150)
  assertEqual "hop B two-sided ATM Y=0" (PayoffX96 0) yAtm
  if yLeft > 0 && yRight > 0
    then putStrLn "ok: hop B two-sided wings Y>0"
    else error "hop B two-sided: expected Y>0 on both wings"
  assertThrows
    "num_legs≠4 rejected"
    (targetVegaFromMint (MintPlan (PanopticTokenId 0 3) (createChunk (-1) 1 1)))

  assertThrows "empty mint list rejected" (targetVegaFromMints [])
  let
    p1 =
      MintPlan
        skeleton
        (createChunk (-20) 20 (positionSizeForTargetVega (mkTargetVega 4)))
    p2 =
      MintPlan
        skeleton
        (createChunk (-20) 20 (positionSizeForTargetVega (mkTargetVega 5)))
  assertEqual
    "ΔQ_v* additive"
    (mkTargetVega 9)
    (targetVegaFromMints [p1, p2])

  assertThrows "skew 0 rejected" (mkVolSkew 0)
  assertThrows "skew 65535 rejected" (mkVolSkew 65535)
  assertThrows "mkVolRangeWidth 0 rejected" (mkVolRangeWidth 0 (mkTickSpacing 10))
  assertEqual "tickVolatilityTick Q96 → 0" 0 (tickVolatilityTick (mkVolStrike Q96))

  -- roundTick: Haskell div already floors toward -∞; must not double-decrement
  -- negative off-grid ticks (regression for the Solidity-style -1 bug).
  assertEqual "roundTick (-5) 10 floors to -10" (-10) (roundTick (-5) (mkTickSpacing 10))
  assertEqual "roundTick (-15) 10 floors to -20" (-20) (roundTick (-15) (mkTickSpacing 10))
  assertEqual "roundTick (-10) 10 on-grid is unchanged" (-10) (roundTick (-10) (mkTickSpacing 10))
  assertEqual "roundTick 5 10 floors to 0" 0 (roundTick 5 (mkTickSpacing 10))
  assertEqual "roundTick 15 10 floors to 10" 10 (roundTick 15 (mkTickSpacing 10))
  assertEqual "roundTick 0 10 is 0" 0 (roundTick 0 (mkTickSpacing 10))
  let
    dqv1 = mkTargetVega 1
    vo = fixtureSymmetricVolOrder dqv1
    (iL, iU, ts) = tickBucketFromVolOrder vo
  assertEqual "fixture i_l" (-20) iL
  assertEqual "fixture i_u" 20 iU
  assertEqual "fixture Δ" 10 (unTickSpacing ts)
  let
    iStar = 0
    (mP, mC) = volOrderSplitPoints iL iU iStar ts
  assertEqual "fixture m_p" (-10) mP
  assertEqual "fixture m_c" 10 mC
  assertEqual
    "fixture four legs"
    [(-20, -10), (-10, 0), (0, 10), (10, 20)]
    (legIntervals vo)

  let
    voVega7 = fixtureSymmetricVolOrder (mkTargetVega 7)
    voRatios = (1, 2, 3, 4)
    voTid = volOrderToTokenId voVega7 0 voRatios
    voPlan = volOrderToMintPlan voVega7 0 voRatios
  assertEqual "volOrder num_legs" 4 (fourLegNumLegs voTid)
  assertEqual
    "volOrder strikes match legs"
    [-15, -5, 5, 15]
    [panopticStrike voTid l | l <- [0, 1, 2, 3]]
  assertEqual "mint plan vega" (mkTargetVega 7) (targetVegaFromMint voPlan)
  assertEqual
    "mint chunk = envelope"
    (-20, 20, 7)
    ( chunkTickLower (mintChunk voPlan)
    , chunkTickUpper (mintChunk voPlan)
    , chunkLiquidity (mintChunk voPlan)
    )
  let
    voFromScalar = scaleByTargetVega (mkTargetVega 7) piLegs
    voFromMint = scaleByTargetVega (targetVegaFromMint voPlan) piLegs
    voY0 = Payoff.runPayoff voFromScalar (sqrtPriceX96 0)
    voY10 = Payoff.runPayoff voFromMint s10
    voY0' = Payoff.runPayoff voFromMint (sqrtPriceX96 0)
    voY10' = Payoff.runPayoff voFromScalar s10
  assertEqual "volOrder mint plan dual-run ATM" voY0 voY0'
  assertEqual "volOrder mint plan dual-run off-ATM" voY10' voY10
  assertThrows
    "volOrderToTokenId optionRatio 0 rejected"
    (volOrderToTokenId voVega7 0 (0, 1, 1, 1))
  assertThrows
    "volOrderToTokenId optionRatio 128 rejected"
    (volOrderToTokenId voVega7 0 (1, 1, 1, 128))

  -- Geometry feasibility guards, tripped by constructed (non-fixture)
  -- VolOrders: width=1/Δ=10 makes every leg span < Δ (span < Δ guard).
  let
    narrowVo =
      mkVolOrder
        (mkVolRangeWidth 1 (mkTickSpacing 10))
        (mkVolStrike Q96)
        (mkVolSkew 32768)
        (mkTargetVega 1)
  assertEqual
    "narrow VolOrder legs collapse below Δ"
    [(-10, -10), (-10, 0), (0, 0), (0, 0)]
    (legIntervals narrowVo)
  assertThrows
    "volOrderToTokenId narrow span < Δ rejected"
    (volOrderToTokenId narrowVo 0 (1, 1, 1, 1))

  -- Skewed (near-max skew=65500) VolOrder: the put side collapses to a
  -- sliver, also tripping the span < Δ guard (and, by construction, would
  -- trip side < 2Δ too if a leg ever cleared span-feasibility on its own —
  -- see fix report for why side < 2Δ is subsumed by the per-leg check here).
  let
    skewedVo =
      mkVolOrder
        (mkVolRangeWidth 40 (mkTickSpacing 10))
        (mkVolStrike Q96)
        (mkVolSkew 65500)
        (mkTargetVega 1)
  assertEqual
    "skewed VolOrder put-side legs collapse below Δ"
    [(-10, -10), (-10, 0), (0, 10), (10, 30)]
    (legIntervals skewedVo)
  assertThrows
    "volOrderToTokenId skewed span < Δ rejected"
    (volOrderToTokenId skewedVo 0 (1, 1, 1, 1))

  -- Packer guards: leg width in tickSpacings must be < 4096 (TokenId width
  -- field is 12 bits), and ticks must satisfy the Uniswap pool bound.
  let
    hugeWidthVo =
      mkVolOrder
        (mkVolRangeWidth 20000 (mkTickSpacing 1))
        (mkVolStrike Q96)
        (mkVolSkew 32768)
        (mkTargetVega 1)
  assertEqual
    "huge-width VolOrder legs each span 5000 spacings"
    [(-10000, -5000), (-5000, 0), (0, 5000), (5000, 10000)]
    (legIntervals hugeWidthVo)
  assertThrows
    "volOrderToTokenId leg width >= 4096 spacings rejected"
    (volOrderToTokenId hugeWidthVo 0 (1, 1, 1, 1))
  let
    SqrtPriceX96 offGridPoolWord = sqrtPriceX96 (uniswapMaxTick + 900)
    extremeVo =
      mkVolOrder
        (mkVolRangeWidth 40 (mkTickSpacing 10))
        (mkVolStrike offGridPoolWord)
        (mkVolSkew 32768)
        (mkTargetVega 1)
  assertThrows
    "volOrderToTokenId tick beyond Uniswap pool bound rejected"
    (volOrderToTokenId extremeVo 0 (1, 1, 1, 1))

  assertThrows "chunk liquidity 0" (createChunk (-20) 20 0)
  assertThrows "chunk inverted ticks" (createChunk 20 (-20) 1)
  let ch = createChunk (-20) 20 7
  assertEqual "chunkTickLower" (-20) (chunkTickLower ch)
  assertEqual "chunkTickUpper" 20 (chunkTickUpper ch)
  assertEqual "chunkLiquidity" 7 (chunkLiquidity ch)
  assertEqual
    "createChunk (-20) 20 7 packs to known Panoptic-layout literal"
    0xffffec0000140000000000000000000000000000000000000000000000000007
    (unLiquidityChunk ch)

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

  -- ExpectedVolatility Slice 1
  let volAvg0 = VolatilityAverage 0
  assertEqual
    "realizedVolatilityFromAverage round-trip"
    0
    (unRealizedVolatility (realizedVolatilityFromAverage volAvg0))
  assertEqual
    "expectedVolatilityWindowStub = realized (Slice 1 stub)"
    0
    (unExpectedVolatility (expectedVolatilityWindowStub volAvg0))
  let
    ipmTen = mkInterestPriceMap 1 0
    t0Vol = mkInterestTick 0
    t7Vol = mkInterestTick 7
    flatPathVol = TickPath 8 (V.replicate 8 0)
    evFlat = expectedVolatilityUniformTenor ipmTen t0Vol t0Vol
    path07 = tenorTickPath ipmTen t0Vol t7Vol
  assertEqual
    "tenorTickPath t0→t7 length"
    8
    (pathLength path07)
  assertEqual
    "tenorTickPath t0 tick"
    0
    (ticks path07 ! 0)
  assertEqual
    "tenorTickPath t7 tick"
    7
    (ticks path07 ! 7)
  assertEqual
    "uniform tenor flat t0=t0 ⇒ σ^e=0"
    0
    (unExpectedVolatility evFlat)
  assertEqual
    "uniform tenor flat matches averageVolatility constant path"
    (unVolatilityAverage (averageVolatility flatPathVol))
    (unExpectedVolatility (expectedVolatilityUniformTenor ipmTen t0Vol t0Vol))
  let
    ivGap = impliedVolatilityFromAverage (VolatilityAverage 100)
    evGap = ExpectedVolatility 40
  assertEqual
    "volGap σ_IV − σ^e"
    60
    (unVolGap (volGap ivGap evGap))
  assertEqual
    "volGap zero when equal"
    0
    (unVolGap (volGap ivGap (ExpectedVolatility 100)))

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
    hopBPlan =
      MintPlan
        (fourLegSkeleton 0 (1, 2, 3, 4))
        (createChunk (-160) 150 (positionSizeForTargetVega (mkTargetVega 1)))
    hopBMin = -160 :: Tick
    hopBIota = mkLadderResolution 32
  assertThrows
    "hop B one-sided iMin=0 rejected"
    (variancePortfolioLayoutVsGamma
      hopBPlan
      n32
      atm0
      (PayoffX96 0)
      (unXiX96 xiPinned)
      BASE_ETA
      spacing10
      (0 :: Tick)
      hopBIota
    )
  _ <- evaluate
    (variancePortfolioLayoutVsGamma
      hopBPlan
      n32
      atm0
      (PayoffX96 0)
      (unXiX96 xiPinned)
      BASE_ETA
      spacing10
      hopBMin
      hopBIota
    )
  _ <- evaluate
    (variancePortfolioLayoutVsXi
      hopBPlan
      n32
      atm0
      (PayoffX96 0)
      xiPinned
      spacing10
      hopBMin
      hopBIota
    )
  putStrLn "ok: hop B Π vs-gamma / vs-xi layouts"

  -- TODO #24 / #35: per-tick CLMM identity (README MODEL_CLOSURE, 2026-08-23).
  -- π^φ(Id_i[𝓛𝓒]; p) = amount0(Id_i) · [π^{c|p}(k½) + π^RAN(k½, r)] exactly,
  -- with k½ = √(p^bid p^ask), r = p^ask/p^bid the SQRT-price ratio
  -- (= 1.0001^{Δ_i/2}), for every p below / in / above the range.
  -- The constant is the unit chunk's token0 amount — per (i, Δ_i), not per Δ_i.
  let identityAt i di p =
        let ch   = unitChunk i (mkTickSpacing di)
            SqrtPriceX96 a = sqrtPriceX96 i
            SqrtPriceX96 b = sqrtPriceX96 (i + di)
            kRaw = floor (sqrt (fromInteger a * fromInteger b :: Double)) :: Integer
            r    = fromInteger b / fromInteger a :: Double
            clmm = CLMM.toPayoff (CLMM.fromCall (StrikeX96 kRaw) (OptionRatio r))
            PayoffX96 lhs = chunkPrincipal ch p
            PayoffX96 c   = Payoff.runPayoff clmm p
            PayoffX96 am0 = chunkAmount0 ch
            rhs  = (am0 * c) `div` Q96
            tol  = max 1 (abs rhs `div` 1000000)  -- 1e-6 rel; X96 floors
        in  if abs (lhs - rhs) <= tol
              then pure ()
              else error ("CLMM identity fails at i=" ++ show i ++ " Δ=" ++ show di
                          ++ " p=" ++ show p ++ ": lhs=" ++ show lhs ++ " rhs=" ++ show rhs)
  sequence_
    [ identityAt i di (sqrtPriceX96 (i + off))
    | (i, di) <- [(0, 10), (0, 60), (-3000, 200), (40000, 10), (-120000, 60)]
    , off <- [-di, -1, 0, 1, di `div` 2, di - 1, di, di + 1, 3 * di]
    ]
  putStrLn "ok: per-tick CLMM identity π^φ(Id_i) = amount0 · CLMMPosition"
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

  -- FeePips / feeFactor (Stremia)
  assertEqual "feePipsScale" 1000000 feePipsScale
  assertThrows "FeePips negative rejected" (mkFeePips (-1))
  assertEqual
    "feeFactor 0 = Q96"
    Q96
    (unFeeFactorX96 (feeFactor (mkFeePips 0)))
  let
    FeeFactorX96 f100 = feeFactor (mkFeePips 100)
    expected100 =
      Q96 + mulX96 100 (Q96 * Q96 `div` feePipsScale)
  assertEqual "feeFactor 100 = Q96 + φ_X96 via mulX96" expected100 f100

  -- Stremia bid/ask payoffs
  let
    mid = SqrtPriceX96 Q96
    φ0 = mkFeePips 0
    φ = mkFeePips 100
    PayoffX96 midP = Payoff.squareSqrtPrice mid
    PayoffX96 ask0 = nakedAskQ96 φ0 mid
    PayoffX96 bid0 = nakedBidQ96 φ0 mid
    PayoffX96 askP = nakedAskQ96 φ mid
    PayoffX96 bidP = nakedBidQ96 φ mid
  assertEqual "ask φ=0 = mid P" midP ask0
  assertEqual "bid φ=0 = mid P" midP bid0
  assertEqual "ask ≥ mid (φ=100)" True (askP >= midP)
  assertEqual "mid ≥ bid (φ=100)" True (midP >= bidP)
  let
    FeeFactorX96 f = feeFactor φ
    expectAsk = PayoffX96 (mulX96 midP f)
    expectBid = PayoffX96 (mulX96 midP (invX96 f))
  assertEqual "nakedAsk = P · feeFactor" expectAsk (nakedAskQ96 φ mid)
  assertEqual "nakedBid = P / feeFactor" expectBid (nakedBidQ96 φ mid)
  assertEqual
    "askPayoff run = nakedAsk"
    (nakedAskQ96 φ mid)
    (Payoff.runPayoff (askPayoff φ) mid)
  assertEqual
    "bidPayoff run = nakedBid"
    (nakedBidQ96 φ mid)
    (Payoff.runPayoff (bidPayoff φ) mid)

  -- PriceImpact fee'd sqrt quotes + consistency with Stremia payoffs
  assertEqual "askSqrt φ=0 = mid" mid (askSqrtPriceX96 φ0 mid)
  assertEqual "bidSqrt φ=0 = mid" mid (bidSqrtPriceX96 φ0 mid)
  let
    askS = askSqrtPriceX96 φ mid
    bidS = bidSqrtPriceX96 φ mid
  assertEqual "askSqrt ≥ mid" True (askS >= mid)
  assertEqual "mid ≥ bidSqrt" True (mid >= bidS)
  let
    FeeFactorX96 fAsk = feeFactor φ
    sf = integerSqrt (fAsk * Q96)
  assertEqual "sqrtFeeFactorX96" sf (sqrtFeeFactorX96 (FeeFactorX96 fAsk))
  assertEqual
    "askSqrt at Q96 mid = sqrtFeeFactor"
    (SqrtPriceX96 sf)
    askS
  assertEqual
    "bidSqrt at Q96 mid = inv sqrtFeeFactor"
    (SqrtPriceX96 (invX96 sf))
    bidS
  let
    PayoffX96 fromSqrtAsk = Payoff.squareSqrtPrice askS
    PayoffX96 fromPayAsk = nakedAskQ96 φ mid
    PayoffX96 fromSqrtBid = Payoff.squareSqrtPrice bidS
    PayoffX96 fromPayBid = nakedBidQ96 φ mid
  assertEqual
    "ask sqrt↔payoff within 1"
    True
    (abs (fromSqrtAsk - fromPayAsk) <= 1)
  assertEqual
    "bid sqrt↔payoff within 1"
    True
    (abs (fromSqrtBid - fromPayBid) <= 1)

  -- Linear + ReturnPips
  assertEqual
    "linearPayoff = squareSqrtPrice at Q96"
    (squareSqrtPrice (SqrtPriceX96 Q96))
    (linearPayoff (SqrtPriceX96 Q96))
  assertEqual
    "linearPayoff = squareSqrtPrice at tick 10"
    (squareSqrtPrice (sqrtPriceX96 10))
    (linearPayoff (sqrtPriceX96 10))
  assertEqual "returnPipsScale" 1000000 returnPipsScale
  let
    retMid = SqrtPriceX96 Q96
    PayoffX96 pd = linearPayoff retMid
  assertEqual
    "mkReturn mid mid = 0"
    0
    (unReturnPips (mkReturn (PayoffX96 pd) (PayoffX96 pd)))
  assertThrows "mkReturn denom 0" (mkReturn (PayoffX96 1) (PayoffX96 0))
  let
    ask3000 = nakedAskQ96 (mkFeePips 3000) retMid
    r3000 = unReturnPips (mkReturn ask3000 (linearPayoff retMid))
  assertEqual "ask3000 vs linear ≈ 3000 pips" True (abs (r3000 - 3000) <= 1)

  -- feePipsFromBidAsk (φ_M = φ_X)
  let
    sFee = SqrtPriceX96 Q96
    midFee = linearPayoff sFee
    rt φWant =
      let got =
            feePipsFromBidAsk
              midFee
              (nakedBidQ96 φWant sFee)
              (nakedAskQ96 φWant sFee)
      in  abs (unFeePips got - unFeePips φWant) <= 1
  assertEqual "feePipsFromBidAsk round-trip 0" True (rt (mkFeePips 0))
  assertEqual "feePipsFromBidAsk round-trip 100" True (rt (mkFeePips 100))
  assertEqual "feePipsFromBidAsk round-trip 3000" True (rt (mkFeePips 3000))
  assertThrows
    "feePipsFromBidAsk disagree"
    (feePipsFromBidAsk
      midFee
      (nakedBidQ96 (mkFeePips 100) sFee)
      (nakedAskQ96 (mkFeePips 3000) sFee))
  assertThrows
    "feePipsFromBidAsk mid 0"
    (feePipsFromBidAsk (PayoffX96 0) (PayoffX96 1) (PayoffX96 1))

  -- One-sided invert + composite
  let
    askP3000 = linearPayoff (askSqrtPriceX96 (mkFeePips 3000) sFee)
    bidP100 = linearPayoff (bidSqrtPriceX96 (mkFeePips 100) sFee)
  assertEqual
    "feePipsFromAsk ≈ 3000"
    True
    (abs (unFeePips (feePipsFromAsk midFee askP3000) - 3000) <= 1)
  assertEqual
    "feePipsFromBid ≈ 100"
    True
    (abs (unFeePips (feePipsFromBid midFee bidP100) - 100) <= 1)
  let
    φM = mkFeePips 3000
    φX = mkFeePips 100
    FeePips mRaw = φM
    FeePips xRaw = φX
    phiMX96 = (mRaw * Q96) `div` feePipsScale
    phiXX96 = (xRaw * Q96) `div` feePipsScale
    expectedComposite =
      mkFeePips $
        ((Q96 - mulX96 (Q96 - phiMX96) (Q96 - phiXX96)) * feePipsScale)
          `div` Q96
  assertEqual
    "compositeFeePips 3000×100"
    expectedComposite
    (compositeFeePips φM φX)

  -- Quote → φ_M / φ_X
  let
    qSym =
      mkQuote
        sFee
        (bidSqrtPriceX96 (mkFeePips 3000) sFee)
        (askSqrtPriceX96 (mkFeePips 3000) sFee)
  assertEqual
    "phiM symmetric ≈ 3000"
    True
    (abs (unFeePips (phiMFromQuote qSym) - 3000) <= 1)
  assertEqual
    "phiX symmetric ≈ 3000"
    True
    (abs (unFeePips (phiXFromQuote qSym) - 3000) <= 1)
  let
    qSplit =
      mkQuote
        sFee
        (bidSqrtPriceX96 (mkFeePips 100) sFee)
        (askSqrtPriceX96 (mkFeePips 3000) sFee)
  assertEqual
    "phiM split ≈ 3000"
    True
    (abs (unFeePips (phiMFromQuote qSplit) - 3000) <= 1)
  assertEqual
    "phiX split ≈ 100"
    True
    (abs (unFeePips (phiXFromQuote qSplit) - 100) <= 1)
  assertThrows
    "mkQuote ask < mid"
    (mkQuote sFee sFee (SqrtPriceX96 (Q96 `div` 2)))

  -- TickLiquidity (geometric at chunk bounds)
  let
    xiTL = xiStar (mkTickSpacing 10)
    chTL = createChunk (-20) (-10) Q96
    loTL = -20 :: Tick
    hiTL = -10 :: Tick
    TickLiquidity tLo lLo = tickLiquidityAt xiTL chTL loTL
    TickLiquidity tHi lHi = tickLiquidityAt xiTL chTL hiTL
  assertEqual "tlTick lo" loTL tLo
  assertEqual "tlTick hi" hiTL tHi
  assertEqual "L(lo) = chunkLiquidity" (chunkLiquidity chTL) lLo
  assertEqual
    "L(hi) = mulX96 L(lo) ξ"
    (mulX96 lLo (unXiX96 xiTL))
    lHi
  assertThrows
    "tickLiquidityAt rejects interior tick"
    (tickLiquidityAt xiTL chTL (-15))

  -- KappaTick / KappaSpacing (encoding C)
  assertEqual "defaultKappaSpacing N" 255 (unKappaSpacing defaultKappaSpacing)
  assertThrows "mkKappaSpacing 254" (mkKappaSpacing 254)
  assertThrows "mkKappaSpacing 0" (mkKappaSpacing 0)
  assertEqual
    "mkKappaSpacing 255"
    defaultKappaSpacing
    (mkKappaSpacing 255)
  let sp = defaultKappaSpacing
  assertThrows "mkKappaTick (-1)" (mkKappaTick sp (-1))
  assertThrows "mkKappaTick 256" (mkKappaTick sp 256)
  assertEqual "mkKappaTick 0" (KappaTick 0) (mkKappaTick sp 0)
  assertEqual "mkKappaTick 255" (KappaTick 255) (mkKappaTick sp 255)
  assertEqual "kappaFromTick 0" 0 (kappaFromTick sp (KappaTick 0))
  assertEqual "kappaFromTick N" 1 (kappaFromTick sp (KappaTick 255))
  assertEqual
    "kappaFromTick 26"
    (26 / 255)
    (kappaFromTick sp (KappaTick 26))
  assertEqual
    "snap 0.1 → 26"
    (KappaTick 26)
    (snapKappaTick sp 0.1)
  assertEqual
    "snap below 0 → 0"
    (KappaTick 0)
    (snapKappaTick sp (-1))
  assertEqual
    "snap above 1 → N"
    (KappaTick 255)
    (snapKappaTick sp 2)
  let
    xiK = xiStar (mkTickSpacing 10)
    chK = createChunk (-20) (-10) Q96
    expectedTick = snapKappaTick defaultKappaSpacing (1 / 10)
    KappaCoordinate gotNothing = kappaAt Nothing xiK chK
    KappaCoordinate gotJust = kappaAt (Just BASE_ETA) xiK chK
  assertEqual "kappaAt Nothing ≡ snap trading base 1/10" expectedTick gotNothing
  assertEqual "kappaAt Just BASE_ETA ≡ Nothing" gotNothing gotJust
  assertEqual "expected KappaTick 26" 26 (unKappaTick expectedTick)

  -- FeePips Monoid (survival stack)
  let
    φ100 = mkFeePips 100
    φ3000 = mkFeePips 3000
    φ500 = mkFeePips 500
  assertEqual
    "FeePips <> ≡ compositeFeePips"
    (compositeFeePips φ3000 φ100)
    (φ3000 <> φ100)
  assertEqual "φ <> mempty" φ3000 (φ3000 <> mempty)
  assertEqual "mempty <> φ" φ3000 (mempty <> φ3000)
  assertEqual
    "FeePips associativity (1 pip)"
    True
    (abs
      ( unFeePips ((φ3000 <> φ100) <> φ500)
          - unFeePips (φ3000 <> (φ100 <> φ500))
      )
      <= 1)
  assertEqual
    "FeePips commutativity (1 pip)"
    True
    (abs (unFeePips (φ3000 <> φ100) - unFeePips (φ100 <> φ3000)) <= 1)

  -- FeeStructure bag + toFeePips
  let
    fs = mkFeeStructure (mkFeePips 100) (mkFeePips 3000)
  assertEqual "feePhiX" (mkFeePips 100) (feePhiX fs)
  assertEqual "feePhiM" (mkFeePips 3000) (feePhiM fs)
  assertEqual
    "toFeePips ≡ compositeFeePips M X"
    (compositeFeePips (mkFeePips 3000) (mkFeePips 100))
    (toFeePips fs)

  -- MarkUpStructure product fold (distinct from survival toFeePips)
  let
    φXmu = mkFeePips 100
    φMmu = mkFeePips 3000
    fsMu = mkFeeStructure φXmu φMmu
    prodManual =
      FeeFactorX96 $
        mulX96
          (unFeeFactorX96 (feeFactor φXmu))
          (unFeeFactorX96 (feeFactor φMmu))
  assertEqual
    "markUpFactors FeeStructure"
    [φXmu, φMmu]
    (markUpFactors fsMu)
  assertEqual
    "markupPhiX / markupPhiM"
    (φXmu, φMmu)
    (markupPhiX fsMu, markupPhiM fsMu)
  assertEqual
    "foldMarkUpFactor = ∏ feeFactor"
    prodManual
    (foldMarkUpFactor fsMu)
  assertEqual
    "foldMarkUpFactor ≠ toFeePips survival composite (non-degenerate)"
    True
    (toFeePips fsMu /= mkFeePips 0 && foldMarkUpFactor fsMu /= feeFactor (toFeePips fsMu))

  -- ExpectedReturn / ReturnFromKappa
  let
    φXer = mkFeePips 100
    φMer = mkFeePips 3000
    fser = mkFeeStructure φXer φMer
    nEr = unKappaSpacing defaultKappaSpacing
    coord0 = KappaCoordinate (KappaTick 0)
    coordN = KappaCoordinate (KappaTick nEr)
    coordMid = KappaCoordinate (KappaTick (nEr `div` 2))
  assertEqual
    "returnFromKappa FeeStructure j=0 → φ_X"
    φXer
    (unExpectedReturn (returnFromKappa coord0 fser))
  assertEqual
    "returnFromKappa FeeStructure j=N → φ_M"
    φMer
    (unExpectedReturn (returnFromKappa coordN fser))
  assertEqual
    "returnFromKappa FeeStructure j=N/2"
    (mkFeePips $
      ((fromIntegral (nEr - nEr `div` 2) * 100)
        + (fromIntegral (nEr `div` 2) * 3000))
        `div` fromIntegral nEr)
    (unExpectedReturn (returnFromKappa coordMid fser))
  assertEqual
    "returnFromKappa FeePips j=0 → 0"
    (mkFeePips 0)
    (unExpectedReturn (returnFromKappa coord0 φMer))
  assertEqual
    "returnFromKappa FeePips j=N → φ"
    φMer
    (unExpectedReturn (returnFromKappa coordN φMer))

  -- InterestSqrtX96 / InterestTick (λ^{t/2} twin of SqrtPriceX96)
  assertEqual "unInterestTick" 10 (unInterestTick (mkInterestTick 10))
  assertEqual
    "interestSqrtX96 t=0 → Q96"
    Q96
    (unInterestSqrtX96 (interestSqrtX96 (mkInterestTick 0)))
  let
    expectInterest t =
      floor $ tickBase ** (fromIntegral t / 2) * fromIntegral Q96 :: Integer
  assertEqual
    "interestSqrt t=1"
    (expectInterest 1)
    (unInterestSqrtX96 (interestSqrtX96 (mkInterestTick 1)))
  assertEqual
    "interestSqrt t=10"
    (expectInterest 10)
    (unInterestSqrtX96 (interestSqrtX96 (mkInterestTick 10)))
  assertEqual
    "interestSqrt t=-10"
    (expectInterest (-10))
    (unInterestSqrtX96 (interestSqrtX96 (mkInterestTick (-10))))
  let
    SqrtPriceX96 p10 = sqrtPriceX96 10
    InterestSqrtX96 i10 = interestSqrtX96 (mkInterestTick 10)
  assertEqual "numeric twin of sqrtPriceX96 @ 10" p10 i10

  -- Savings payoff (interest linear Y = s_r²)
  let
    s0 = interestSqrtX96 (mkInterestTick 0)
    s10Sav = interestSqrtX96 (mkInterestTick 10)
    InterestSqrtX96 w10Sav = s10Sav
  assertEqual
    "savings t=0 → Q96"
    (PayoffX96 Q96)
    (savingsPayoff s0)
  assertEqual
    "savings = s²/Q96 @ t=10"
    (PayoffX96 ((w10Sav * w10Sav) `div` Q96))
    (savingsPayoff s10Sav)
  assertEqual
    "numeric twin of squareSqrtPrice on same word"
    (squareSqrtPrice (SqrtPriceX96 w10Sav))
    (savingsPayoff (InterestSqrtX96 w10Sav))

  -- Swap / FeeStructure (Pay Linear×(1-φ_X), Receive Savings×(1-φ_M))
  assertEqual "survival 0" Q96 (survivalFactorX96 (mkFeePips 0))
  let
    φX = mkFeePips 100
    φM = mkFeePips 3000
    fs = mkFeeStructure φX φM
    sw = swapFromFeeStructure fs
    Swap (Leg payPf) (Leg recvPf) = sw
    s0Price = sqrtPriceX96 0
    sr0 = interestSqrtX96 (mkInterestTick 0)
  assertEqual
    "pay @ 0 ≡ scale linear (1-φ_X)"
    (scalePayoffX96 (survivalFactorX96 φX) (linearPayoff s0Price))
    (Payoff.runPayoff payPf s0Price)
  assertEqual
    "recv @ 0 ≡ scale savings (1-φ_M)"
    (scalePayoffX96 (survivalFactorX96 φM) (savingsPayoff sr0))
    (Payoff.runPayoff recvPf sr0)
  assertEqual
    "savings Payoff t=0"
    (PayoffX96 Q96)
    (Payoff.runPayoff savings sr0)

  -- InterestPriceMap + Swap net along tenor
  assertThrows "InterestPriceMap k=0" (mkInterestPriceMap 0 0)
  assertEqual
    "priceTickAt k=1 i0=0 t=7"
    7
    (priceTickAt (mkInterestPriceMap 1 0) (mkInterestTick 7))
  assertEqual
    "priceTickAt k=2 i0=5 t=3"
    11
    (priceTickAt (mkInterestPriceMap 2 5) (mkInterestTick 3))
  let
    map0 = mkInterestPriceMap 1 0
    t0Net = mkInterestTick 0
    PayoffX96 yr0 = Payoff.runPayoff recvPf (interestSqrtX96 t0Net)
    PayoffX96 yp0 =
      Payoff.runPayoff payPf (sqrtPriceX96 (priceTickAt map0 t0Net))
    expectedNet = PayoffX96 (yr0 - yp0)
  assertEqual
    "alongTenor t=0 ≡ recv − pay"
    expectedNet
    (runSwapAlongTenor map0 sw t0Net)

  let
    reZero = ExpectedReturn (mkFeePips 0)
    reFull = ExpectedReturn (mkFeePips feePipsScale)
  assertEqual "weight r=0 → 0" 0 (expectedReturnWeightX96 reZero)
  assertEqual
    "weight full scale → Q96"
    Q96
    (expectedReturnWeightX96 reFull)
  let
    PayoffX96 yMix0 =
      runSwapAlongTenorMixture map0 reZero (swapFromFeeStructure fs) t0Net
    PayoffX96 ypOnly =
      Payoff.runPayoff payPf (sqrtPriceX96 (priceTickAt map0 t0Net))
  assertEqual "mixture w=0 ≡ Y_pay" ypOnly yMix0
  let
    PayoffX96 yMix1 =
      runSwapAlongTenorMixture map0 reFull (swapFromFeeStructure fs) t0Net
    PayoffX96 yrOnly =
      Payoff.runPayoff recvPf (interestSqrtX96 t0Net)
  assertEqual "mixture w=1 ≡ Y_recv" yrOnly yMix1
  let
    Swap (Leg pA) (Leg rA) =
      swapParameterized (KappaCoordinate (KappaTick 0)) fs
    Swap (Leg pB) (Leg rB) = swapFromFeeStructure fs
  assertEqual
    "swapParameterized pay @0 ≡ swapFromFeeStructure"
    (Payoff.runPayoff pB s0Price)
    (Payoff.runPayoff pA s0Price)
  assertEqual
    "swapParameterized recv @0 ≡ swapFromFeeStructure"
    (Payoff.runPayoff rB sr0)
    (Payoff.runPayoff rA sr0)

  -- TransactionalFeeCapture (π^φ)
  assertEqual "feeFactorX96 0" 0 (feeFactorX96 (mkFeePips 0))
  let
    fs0 = mkFeeStructure (mkFeePips 0) (mkFeePips 0)
    fc0 = transactionalFeeCaptureFromFeeStructure fs0
    TransactionalFeeCapture (Leg capPay0) (Leg capRecv0) = fc0
    s0fc = sqrtPriceX96 0
    sr0fc = interestSqrtX96 (mkInterestTick 0)
  assertEqual
    "capture φ=0 pay ≡ 0"
    (PayoffX96 0)
    (Payoff.runPayoff capPay0 s0fc)
  assertEqual
    "capture φ=0 recv ≡ 0"
    (PayoffX96 0)
    (Payoff.runPayoff capRecv0 sr0fc)
  assertEqual
    "pay partition φ=0"
    0
    (payPartitionErrorX96 fs0 s0fc)
  assertEqual
    "recv partition φ=0"
    0
    (recvPartitionErrorX96 fs0 sr0fc)

  let
    fsCap = mkFeeStructure (mkFeePips 100) (mkFeePips 3000)
    sCap = sqrtPriceX96 0
    srCap = interestSqrtX96 (mkInterestTick 0)
  assertEqual
    "pay partition ≤1"
    True
    (payPartitionErrorX96 fsCap sCap <= 1)
  assertEqual
    "recv partition ≤1"
    True
    (recvPartitionErrorX96 fsCap srCap <= 1)
  assertEqual
    "assertAccountingIdentityWithSwap"
    ()
    (assertAccountingIdentityWithSwap fsCap sCap srCap)

  let
    fcCap = transactionalFeeCaptureFromFeeStructure fsCap
    mapCap = mkInterestPriceMap 1 0
    t0Cap = mkInterestTick 0
    TransactionalFeeCapture (Leg capPay) (Leg capRecv) = fcCap
    PayoffX96 ypCap =
      Payoff.runPayoff capPay (sqrtPriceX96 (priceTickAt mapCap t0Cap))
    PayoffX96 yrCap =
      Payoff.runPayoff capRecv (interestSqrtX96 t0Cap)
  assertEqual
    "fee capture along tenor ≡ sum"
    (PayoffX96 (ypCap + yrCap))
    (runFeeCaptureAlongTenor mapCap fcCap t0Cap)

  -- π^φ(r_φ^e): feeRevenueExpectedReturn + mixture
  let
    reFullCap = ExpectedReturn (mkFeePips feePipsScale)
    reZeroCap = ExpectedReturn (mkFeePips 0)
    rPhiFull = feeRevenueExpectedReturn fsCap reFullCap
    rPhiZero = feeRevenueExpectedReturn fsCap reZeroCap
  assertEqual
    "feeRevenueExpectedReturn r^e=0 → 0"
    (mkFeePips 0)
    (unExpectedReturn rPhiZero)
  assertEqual
    "feeRevenueExpectedReturn r^e=scale → φ"
    (toFeePips fsCap)
    (unExpectedReturn rPhiFull)
  let
    PayoffX96 yCapMix0 =
      runFeeCaptureAlongTenorMixture mapCap rPhiZero fcCap t0Cap
  assertEqual "fee capture mixture w=0 ≡ Y_pay" ypCap yCapMix0
  let
    -- Full weight on recv: use ExpectedReturn at feePipsScale as r_φ^e directly
    rPhiAsWeight1 = ExpectedReturn (mkFeePips feePipsScale)
    PayoffX96 yCapMix1 =
      runFeeCaptureAlongTenorMixture mapCap rPhiAsWeight1 fcCap t0Cap
  assertEqual "fee capture mixture w=1 ≡ Y_recv" yrCap yCapMix1
