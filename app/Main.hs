{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MonoLocalBinds #-}

module Main (main) where

import System.Directory (createDirectoryIfMissing)

import OptionRatio (OptionRatio(..))
import Plotting.PlotUtils (Panel(..), writePanel)
import Pricing.PriceDeformation
  ( EtaX96(..)
  , deformationLayout
  , plotDeformation
  , plotVarSigmaEta
  , pattern BASE_ETA
  )
import Pricing.Stremia
  ( defaultFeePipsGrid
  , mkFeePips
  , nakedAskQ96
  , nakedBidQ96
  , plotFeeRateVsSqrt
  , plotFeeVsReturn
  )
import Payoffs.Linear (linearPayoff)
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction, sqrtFunctionLayout)
import Plotting.PlotInterest
  ( InterestPlot(..)
  , plotInterestFunction
  , plotInterestTickFunction
  )
import Payoffs.Savings (savingsPayoff)
import Payoffs.Swap
  ( Leg(..)
  , Swap(..)
  , runSwapAlongTenor
  , swapFromFeeStructure
  )
import Payoffs.TransactionalFeeCapture
  ( TransactionalFeeCapture(..)
  , runFeeCaptureAlongTenor
  , transactionalFeeCaptureFromFeeStructure
  )
import Pricing.FeeStructure (mkFeeStructure)
import Pricing.InterestPriceMap (mkInterestPriceMap)
import Pricing.InterestSqrt (interestSqrtX96, mkInterestTick)
import qualified Payoffs.Payoff as Payoff
import Greeks.Delta (deltaLayout)
import Greeks.Gamma (gammaLayout, kristensenGammaLayoutVsGamma)
import Payoffs.CLMMPosition (chunkFromStrike, rhsPayoffLayout, scaledVsUnitLayout)
import Payoffs.Forward (AtmForward(..))
import Payoffs.Log (nakedLogQ96, nakedLogTickQ96)
import Panoptic.NId (MintPlan(..), fourLegSkeleton, mkNId, volOrderToMintPlan)
import Payoffs.VolatilityReplica (ErrorX96(..), legsLayout, replicaError, replicaLayout, windowTicks)
import Panoptic.Binning (binToLegs, ladderFromVolOrder, mintPlanFromLadder, quantizationReport)
import Payoffs.LadderPosition (ladderN1, ladderT1)
import Volatility.VolOrder (VolOrder, mkVolOrder, mkVolRangeWidth, mkVolSkew)
import Payoffs.VolatilityReplica (fourLegReplica)
import Panoptic.NId (volOrderToTokenId)
import qualified Payoffs.PathAccrual as PA
import Payoffs.LadderPosition (cOfS, ladderDensityLayout, ladderFromSpan, ladderLayout, ladderReturnQ96, logPortfolioQ96)
import Volatility.VolOrder (fixtureSymmetricVolOrder)
import TargetVega (mkTargetVega, positionSizeForTargetVega)
import Liquidity.LiquidityChunk
  ( chunkLiquidity
  , chunkTickLower
  , chunkTickUpper
  , createChunk
  )
import Payoffs.VariancePortfolio
  ( variancePortfolioLayout
  , variancePortfolioLayoutVsGamma
  , variancePortfolioLayoutVsXi
  )
import Payoffs.VolatilityCall
  ( mkVolStrike
  , volatilityCallLayout
  , volatilityCallLayoutVsSqrtPrice
  , volatilityCallLayoutVsXi
  )
import Liquidity.LiquidityGrid
  ( liquidityLayout
  , liquidityLayoutVsGamma
  , liquidityLayoutVsSqrtPrice
  , mkLadderResolution
  , unXiX96
  , xiStar
  )
import SqrtGrid
  ( SqrtPlot(..)
  , SqrtPriceX96(..)
  , PayoffX96(..)
  , mkTickSpacing
  , pattern Q96
  , sqrtPriceX96
  , mulDiv
  )
import State
  ( pattern SQRT_PRICE_1_4
  , pattern SQRT_PRICE_4_1
  )
import TickPath (mkTickPath, tickPathLayout)
import Volatility.CevField
  ( cevLayoutVsGamma
  , cevLayoutVsSqrtPrice
  , cevLayoutVsXi
  )
import Volatility.VolTermStructure (BarL(..), FlowVol(..), cevFromPhi)
import StrikeX96 (strike)

-- Avoid DuplicateRecordFields update/selector ambiguity with InterestPlot.
retitleSqrt :: SqrtPlot -> String -> String -> SqrtPlot
retitleSqrt (SqrtPlot _ xa _ xmin xmax) title ya =
  SqrtPlot title xa ya xmin xmax

main :: IO ()
main = do
  createDirectoryIfMissing True "outputs/Pricing"
  createDirectoryIfMissing True "outputs/Payoffs"
  createDirectoryIfMissing True "outputs/Payoffs/Returns"
  createDirectoryIfMissing True "outputs/Greeks"
  createDirectoryIfMissing True "outputs/Liquidity"
  createDirectoryIfMissing True "outputs/TickPath"
  createDirectoryIfMissing True "outputs/Volatility"

  let
    tickLo = -13863
    tickHi = 13863
    etaTwoThirds = EtaX96 $ (2 * Q96) `div` 3
    deformTitle = "p_{1/2}(i; η) vs p_{1/2}(i), ς = η/(1-η)"

    config =
      SqrtPlot
        { plotTitle  = "Call, Range (η=1/2), CPMM (η=1/2 and 2/3)"
        , xAxisTitle = "sqrtPriceX96"
        , yAxisTitle = "PayoffX96"
        , xMin       = SQRT_PRICE_1_4
        , xMax       = SQRT_PRICE_4_1
        }

    strikePrice =
      strike SQRT_PRICE_1_4 SQRT_PRICE_4_1

    ratio = OptionRatio 4.0

  plotDeformation
    "outputs/Pricing/price-deformation.png"
    deformTitle
    tickLo
    tickHi
    [etaTwoThirds]

  plotVarSigmaEta
    "outputs/Pricing/varsigma-eta.png"

  plotSqrtFunction
    "outputs/Payoffs/Returns/stremia-bid-ask.png"
    (retitleSqrt config
      "mid / ask/bid ReturnPips (FeePips 100 & 3000)"
      "ReturnPips")
    ReturnY
    [ linearPayoff
    , nakedAskQ96 (mkFeePips 100)
    , nakedBidQ96 (mkFeePips 100)
    , nakedAskQ96 (mkFeePips 3000)
    , nakedBidQ96 (mkFeePips 3000)
    ]

  let feeMid = SqrtPriceX96 Q96
  plotFeeVsReturn
    "outputs/Payoffs/Returns/stremia-fee-vs-return.png"
    feeMid
    defaultFeePipsGrid
  plotFeeRateVsSqrt
    "outputs/Payoffs/Returns/stremia-fee-rate-vs-sqrt.png"
    feeMid
    defaultFeePipsGrid

  createDirectoryIfMissing True "outputs/Payoffs"
  plotInterestFunction
    "outputs/Payoffs/savings-vs-interestSqrtX96.png"
    InterestPlot
      { plotTitle = "savingsPayoff vs interestSqrtX96"
      , xAxisTitle = "interestSqrtX96"
      , yAxisTitle = "PayoffX96"
      , xMin = interestSqrtX96 (mkInterestTick (-100))
      , xMax = interestSqrtX96 (mkInterestTick 100)
      }
    PayoffY
    [savingsPayoff]

  let
    fsDemo = mkFeeStructure (mkFeePips 100) (mkFeePips 3000)
    swDemo = swapFromFeeStructure fsDemo
    Swap (Leg payPf) (Leg recvPf) = swDemo
    ipmDemo = mkInterestPriceMap 1 0
    tLo = mkInterestTick (-100)
    tHi = mkInterestTick 100
  plotSqrtFunction
    "outputs/Payoffs/swap-pay-linear-vs-sqrtPriceX96.png"
    (retitleSqrt config
      "Swap pay: linear×(1-φ_X) (φ_X=100)"
      "PayoffX96")
    PayoffY
    [Payoff.runPayoff payPf]
  plotInterestFunction
    "outputs/Payoffs/swap-receive-savings-vs-interestSqrtX96.png"
    InterestPlot
      { plotTitle = "Swap receive: savings×(1-φ_M) (φ_M=3000)"
      , xAxisTitle = "interestSqrtX96"
      , yAxisTitle = "PayoffX96"
      , xMin = interestSqrtX96 tLo
      , xMax = interestSqrtX96 tHi
      }
    PayoffY
    [Payoff.runPayoff recvPf]
  plotInterestTickFunction
    "outputs/Payoffs/swap-net-vs-interestSqrtX96.png"
    InterestPlot
      { plotTitle = "Swap net: recv−pay along i=k·t+i₀ (k=1,i₀=0)"
      , xAxisTitle = "interestSqrtX96"
      , yAxisTitle = "PayoffX96"
      , xMin = interestSqrtX96 tLo
      , xMax = interestSqrtX96 tHi
      }
    PayoffY
    tLo
    tHi
    [runSwapAlongTenor ipmDemo swDemo]

  let
    fcDemo = transactionalFeeCaptureFromFeeStructure fsDemo
    TransactionalFeeCapture (Leg capPayPf) (Leg capRecvPf) = fcDemo
  plotSqrtFunction
    "outputs/Payoffs/fee-capture-pay-vs-sqrtPriceX96.png"
    (retitleSqrt config
      "Fee capture pay: linear×φ_X (φ_X=100)"
      "PayoffX96")
    PayoffY
    [Payoff.runPayoff capPayPf]
  plotInterestFunction
    "outputs/Payoffs/fee-capture-receive-vs-interestSqrtX96.png"
    InterestPlot
      { plotTitle = "Fee capture receive: savings×φ_M (φ_M=3000)"
      , xAxisTitle = "interestSqrtX96"
      , yAxisTitle = "PayoffX96"
      , xMin = interestSqrtX96 tLo
      , xMax = interestSqrtX96 tHi
      }
    PayoffY
    [Payoff.runPayoff capRecvPf]
  plotInterestTickFunction
    "outputs/Payoffs/fee-capture-sum-vs-interestSqrtX96.png"
    InterestPlot
      { plotTitle = "Fee capture sum: pay+recv along i=k·t+i₀ (k=1,i₀=0)"
      , xAxisTitle = "interestSqrtX96"
      , yAxisTitle = "PayoffX96"
      , xMin = interestSqrtX96 tLo
      , xMax = interestSqrtX96 tHi
      }
    PayoffY
    tLo
    tHi
    [runFeeCaptureAlongTenor ipmDemo fcDemo]

  writePanel
    "outputs/Pricing/panel-deformation-cpmm.png"
    (Beside
      (Cell (deformationLayout deformTitle tickLo tickHi [etaTwoThirds]))
      (Cell (rhsPayoffLayout config strikePrice ratio etaTwoThirds))
    )

  writePanel
    "outputs/Greeks/panel-payoff-delta.png"
    (Beside
      (Cell (rhsPayoffLayout config strikePrice ratio etaTwoThirds))
      (Cell (deltaLayout config strikePrice ratio))
    )

  writePanel
    "outputs/Greeks/panel-payoff-gamma.png"
    (Beside
      (Cell (rhsPayoffLayout config strikePrice ratio etaTwoThirds))
      (Cell (gammaLayout config strikePrice ratio))
    )

  -- TODO #27: CLMMPosition is chunk-constructed. Unit chunk of (k, r)
  -- (amount0 = 1 token0) vs the same ticks at 2× liquidity (amount0 = 2).
  let
    unitCh   = chunkFromStrike strikePrice ratio
    doubleCh = createChunk (chunkTickLower unitCh) (chunkTickUpper unitCh) (2 * chunkLiquidity unitCh)
  writePanel
    "outputs/Payoffs/clmm-chunk-vs-unit.png"
    (Cell (scaledVsUnitLayout
             (retitleSqrt config "CLMMPosition: unit chunk vs 2× liquidity chunk (amount0 scale)" "PayoffX96")
             doubleCh))

  let
    spacing10 = mkTickSpacing 10
    iota32 = mkLadderResolution 32
    xiPinned = xiStar spacing10
    tickMin = 0

  writePanel
    "outputs/Greeks/vs-gammaCoordinate.png"
    (Cell
      (kristensenGammaLayoutVsGamma
        strikePrice
        ratio
        (unXiX96 xiPinned)
        BASE_ETA
        spacing10
        tickMin
        32
      )
    )

  writePanel
    "outputs/Liquidity/vs-xiCoordinate.png"
    (Cell (liquidityLayout xiPinned iota32))

  writePanel
    "outputs/Liquidity/vs-gammaCoordinate.png"
    (Cell (liquidityLayoutVsGamma xiPinned BASE_ETA spacing10 tickMin iota32))

  writePanel
    "outputs/Liquidity/vs-sqrtPriceX96.png"
    (Cell (liquidityLayoutVsSqrtPrice xiPinned spacing10 tickMin iota32))

  let
    vtsCev = cevFromPhi BASE_ETA (BarL 2) (FlowVol 1)
    pathPlot = mkTickPath 32 vtsCev 42 0
  writePanel
    "outputs/TickPath/vs-steps.png"
    (Cell (tickPathLayout pathPlot))

  writePanel
    "outputs/Payoffs/vs-gammaCoordinate.png"
    (Cell
      (volatilityCallLayout
        (mkVolStrike 0)
        (unXiX96 xiPinned)
        BASE_ETA
        spacing10
        tickMin
        iota32
      )
    )

  writePanel
    "outputs/Payoffs/vs-sqrtPriceX96.png"
    (Cell
      (volatilityCallLayoutVsSqrtPrice
        (mkVolStrike 0)
        spacing10
        tickMin
        iota32
      )
    )

  writePanel
    "outputs/Payoffs/vs-xiCoordinate.png"
    (Cell
      (volatilityCallLayoutVsXi
        (mkVolStrike 0)
        xiPinned
        spacing10
        tickMin
        iota32
      )
    )

  writePanel
    "outputs/Volatility/vs-sqrtPriceX96.png"
    (Cell (cevLayoutVsSqrtPrice vtsCev spacing10 tickMin iota32))

  writePanel
    "outputs/Volatility/vs-gammaCoordinate.png"
    (Cell
      (cevLayoutVsGamma
        vtsCev
        (unXiX96 xiPinned)
        BASE_ETA
        spacing10
        tickMin
        iota32
      )
    )

  writePanel
    "outputs/Volatility/vs-xiCoordinate.png"
    (Cell (cevLayoutVsXi vtsCev xiPinned spacing10 tickMin iota32))

  writePanel
    "outputs/Payoffs/variance-portfolio.png"
    (Cell
      (variancePortfolioLayout
        (mkNId 32)
        (AtmForward (sqrtPriceX96 0))
        (PayoffX96 0)
        (mkTargetVega 1)
        SQRT_PRICE_1_4
        SQRT_PRICE_4_1
      )
    )

  let
    hopBPlan =
      MintPlan
        (fourLegSkeleton 0 (1, 2, 3, 4))
        (createChunk (-160) 150 (positionSizeForTargetVega (mkTargetVega 1)))
    hopBAtm = AtmForward (sqrtPriceX96 0)
    hopBNid = mkNId 32
    hopBMin = -160

  -- TODO #25 (#36): the 4-leg replica π̂^σ from leg chunks (fixture VolOrder,
  -- legs ±20 ticks about i* = 0, ΔQ_υ = 1e18, or = (1,2,3,4)).
  let
    replicaPlan = volOrderToMintPlan (fixtureSymmetricVolOrder (mkTargetVega (10 ^ (18 :: Int)))) 0 (1, 2, 3, 4)
    replicaCfg  = SqrtPlot
      { plotTitle  = "π̂^σ = Σ_leg [H_leg − π^φ(LC_leg)] (4-leg Panoptic, ΔQ_υ = 1e18)"
      , xAxisTitle = "sqrtPriceX96"
      , yAxisTitle = "PayoffX96 (token1)"
      , xMin       = sqrtPriceX96 (-60)
      , xMax       = sqrtPriceX96 60
      }
    legsCfg = retitleSqrt replicaCfg "Per-leg terms H_leg − π^φ(LC_leg) and their sum" "PayoffX96 (token1)"
    pStar0  = sqrtPriceX96 0
  writePanel
    "outputs/Payoffs/Replica/panel-legs-replica.png"
    (Beside
      (Cell (legsLayout legsCfg replicaPlan))
      (Cell (replicaLayout replicaCfg replicaPlan pStar0 []))
    )

  -- TODO #28.2: T1 geometric ladder (S = 4000, Δ = 10, ι = 400, ξ*) — README § REPLICATION_THEORY
  -- Theorem 10 overlay (same units: T1/N_1 vs c(S)·logPortfolio), residual, rung density.
  let
    ladT1  = ladderFromSpan (-2000) 2000 spacing10 0 (mkTargetVega (10 ^ (24 :: Int)))
    cS     = cOfS 4000
    t1Cfg  = SqrtPlot
      { plotTitle  = "Thm 10: T1/N_1 (geometric ladder at ξ*, S=4000, Δ=10) vs c(S)·logPortfolio, c = " ++ take 7 (show cS)
      , xAxisTitle = "sqrtPriceX96"
      , yAxisTitle = "return (Q96)"
      , xMin       = sqrtPriceX96 (-2000)
      , xMax       = sqrtPriceX96 2000
      }
    resCfg = retitleSqrt t1Cfg "residual T1/N_1 − c(S)·logPortfolio (Q96)" "Q96"
    resid p = let PayoffX96 a = ladderReturnQ96 ladT1 p
                  PayoffX96 b = logPortfolioQ96 p (sqrtPriceX96 0)
              in  PayoffX96 (a - floor (cS * fromIntegral b))
    denCfg = retitleSqrt t1Cfg "rung liquidity L(i_x) = ΔQ·ℓ(ξ*, ι; x) (Thm 7)" "liquidity"
  writePanel
    "outputs/Payoffs/Replica/panel-t1-vs-t0.png"
    (Beside
      (Cell (ladderLayout t1Cfg ladT1))
      (Cell (sqrtFunctionLayout resCfg PayoffY [("residual", resid)]))
    )
  writePanel
    "outputs/Payoffs/Replica/t1-ladder-density.png"
    (Cell (ladderDensityLayout denCfg ladT1))

  -- TODO #28.3: 𝓑 binning of the ξ* ladder into 4 legs; T2 vs T1 (both / N_1); width sweep.
  let
    voOf :: Int -> VolOrder
    voOf s = mkVolOrder (mkVolRangeWidth (toInteger s) spacing10) (mkVolStrike Q96) (mkVolSkew 32768) (mkTargetVega (10 ^ (24 :: Int)))
    vo4k   = voOf 4000
    lad4k  = ladderFromVolOrder vo4k
    plan4k = mintPlanFromLadder 0 lad4k vo4k
    PayoffX96 n1B = ladderN1 lad4k
    normBy y = PayoffX96 (mulDiv y Q96 n1B)
    t1n p = let PayoffX96 y = Payoff.runPayoff (ladderT1 lad4k) p in normBy y
    t2n p = let PayoffX96 y = Payoff.runPayoff (fourLegReplica plan4k (sqrtPriceX96 0)) p in normBy y
    fixn p = let PayoffX96 y = Payoff.runPayoff (fourLegReplica (MintPlan (volOrderToTokenId vo4k 0 (1,2,3,4)) (mintChunk plan4k)) (sqrtPriceX96 0)) p in normBy y
    (orsB, _) = binToLegs 8 lad4k vo4k
    t2Cfg = SqrtPlot
      { plotTitle  = "T2 = 𝓑(T1) 4-leg (or = " ++ show orsB ++ ") vs T1 ladder, both / N_1 (S=4000, Δ=10)"
      , xAxisTitle = "sqrtPriceX96"
      , yAxisTitle = "return (Q96)"
      , xMin       = sqrtPriceX96 (-3000)
      , xMax       = sqrtPriceX96 3000
      }
    fixCfg = retitleSqrt t2Cfg "fixture or = (1,2,3,4) vs T1 (for contrast)" "return (Q96)"
  writePanel
    "outputs/Payoffs/Replica/panel-t2-vs-t1.png"
    (Beside
      (Cell (sqrtFunctionLayout t2Cfg PayoffY [("T1 ladder", t1n), ("T2 = 𝓑(T1)", t2n)]))
      (Cell (sqrtFunctionLayout fixCfg PayoffY [("T1 ladder", t1n), ("T2 fixture (1,2,3,4)", fixn)]))
    )
  -- width sweep: e^σ_W(𝓑) vs span S (stride 50 on 3× span)
  let
    sweep = [ (s, e)
            | s <- [400, 1000, 2000, 4000, 8000]
            , let vo = voOf s
            , let lad = ladderFromVolOrder vo
            , let ErrorX96 e = replicaError lad (mintPlanFromLadder 0 lad vo) (windowTicks vo 50) ]
  putStrLn "width sweep S → e^σ_W(𝓑):"
  mapM_ (\(s, e) -> putStrLn ("  S=" ++ show s ++ "  e=" ++ show (fromIntegral e / fromIntegral Q96 :: Double))) sweep
  putStrLn "quantization report S=4000 (leg, or, relErr ppm, bound ppm):"
  mapM_ print (quantizationReport lad4k vo4k)

  -- TODO #30: path accrual comparative statics on the 𝓑 plan (S=4000):
  -- (a) vs atomic arb share at fixed step size; (b) vs step size (vol proxy) at share 50%.
  let
    phiXa = mkFeePips 500
    phiMa = mkFeePips 3000
    toD :: Integer -> Double
    toD x = fromIntegral x / 1.0e18   -- token1 units (ΔQ_υ = 1e24 liquidity on the 𝓑 plan)
    totalA accs = foldr PA.addAccrual PA.zeroAccrual accs
    rowFor :: Int -> Int -> (Integer, Integer, Integer, Integer, Integer)
    rowFor step sharePct =
      let path = PA.syntheticPath 11 0 step 400 (PA.mkArbShareWad (toInteger sharePct * PA.WAD_SHARE `div` 100))
          acc  = totalA (PA.planAccrual phiXa phiMa plan4k path)
          (PayoffX96 lvrN, PayoffX96 net) = PA.netAccrual acc
      in  (PA.feesTrans acc, PA.feesArb acc, PA.lvrGross acc, lvrN, net)
    sharesA = [0, 10 .. 100] :: [Int]
    bySh = [ (fromIntegral s / 100, rowFor 20 s) | s <- sharesA ]
    stepsA = [5, 10, 20, 40, 60, 80, 120, 160, 240] :: [Int]
    bySt = [ (fromIntegral st, rowFor st 50) | st <- stepsA ]
    pick f xs = [ (x, toD (f r)) | (x, r) <- xs ]
    s1 (a,_,_,_,_) = a; s2 (_,b,_,_,_) = b; s3 (_,_,c,_,_) = c; s4 (_,_,_,d,_) = d; s5 (_,_,_,_,e) = e
  writePanel
    "outputs/Payoffs/Accrual/panel-accrual-vs-arbshare.png"
    (Beside
      (Cell (PA.linesLayout "4-leg accrual vs [ν_arb/ν] (step 20 ticks, 400 steps, φ_X=5bp φ_M=30bp)" "[ν_arb/ν]" "token1"
        [("fees_trans", pick s1 bySh), ("fees_arb", pick s2 bySh), ("LVR_gross", pick s3 bySh)]))
      (Cell (PA.linesLayout "net: LVR_net = LVR_gross − fees_arb;  π^φ = fees_trans − LVR_net" "[ν_arb/ν]" "token1"
        [("LVR_net", pick s4 bySh), ("π^φ (seller net)", pick s5 bySh)]))
    )
  writePanel
    "outputs/Payoffs/Accrual/panel-accrual-vs-vol.png"
    (Beside
      (Cell (PA.linesLayout "4-leg accrual vs step size (vol proxy), share 50%" "step (ticks)" "token1"
        [("fees_trans", pick s1 bySt), ("fees_arb", pick s2 bySt), ("LVR_gross", pick s3 bySt)]))
      (Cell (PA.linesLayout "LVR_net crosses zero where the step exceeds the fee band" "step (ticks)" "token1"
        [("LVR_net", pick s4 bySt), ("π^φ (seller net)", pick s5 bySt)]))
    )

  -- TODO #28.1 evidence: tick-quantized log (pre-#64, staircase) vs continuous
  -- lnQ96 on ±30 ticks, and their difference (bounded by ½ ln λ · Q96).
  let
    logCfg = SqrtPlot
      { plotTitle  = "ln(p/p*) in Q96: tick-quantized (nakedLogTickQ96) vs continuous (lnQ96)"
      , xAxisTitle = "sqrtPriceX96"
      , yAxisTitle = "PayoffX96"
      , xMin       = sqrtPriceX96 (-30)
      , xMax       = sqrtPriceX96 30
      }
    logDiffCfg = retitleSqrt logCfg "difference: tick − continuous (sawtooth, |·| ≤ ½ ln λ · Q96)" "PayoffX96"
    tickLog p = nakedLogTickQ96 p hopBAtm
    contLog p = nakedLogQ96 p hopBAtm
    logDiff p = let PayoffX96 a = tickLog p; PayoffX96 b = contLog p in PayoffX96 (a - b)
  writePanel
    "outputs/Payoffs/Replica/panel-log-tick-vs-continuous.png"
    (Beside
      (Cell (sqrtFunctionLayout logCfg PayoffY [("tick-quantized", tickLog), ("continuous lnQ96", contLog)]))
      (Cell (sqrtFunctionLayout logDiffCfg PayoffY [("tick − continuous", logDiff)]))
    )

  writePanel
    "outputs/Payoffs/variance-portfolio-vs-gammaCoordinate.png"
    (Cell
      (variancePortfolioLayoutVsGamma
        hopBPlan
        hopBNid
        hopBAtm
        (PayoffX96 0)
        (unXiX96 xiPinned)
        BASE_ETA
        spacing10
        hopBMin
        iota32
      )
    )
  writePanel
    "outputs/Payoffs/variance-portfolio-vs-xiCoordinate.png"
    (Cell
      (variancePortfolioLayoutVsXi
        hopBPlan
        hopBNid
        hopBAtm
        (PayoffX96 0)
        xiPinned
        spacing10
        hopBMin
        iota32
      )
    )
