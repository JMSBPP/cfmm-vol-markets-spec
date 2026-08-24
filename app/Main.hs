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
import Plotting.PlotSqrt (PlotY(..), plotSqrtFunction)
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
import Panoptic.NId (MintPlan(..), fourLegSkeleton, mkNId)
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
