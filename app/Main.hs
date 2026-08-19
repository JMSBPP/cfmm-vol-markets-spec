{-# LANGUAGE PatternSynonyms #-}

module Main (main) where

import System.Directory (createDirectoryIfMissing)

import OptionRatio (OptionRatio(..))
import PlotUtils (Panel(..), writePanel)
import Pricing.PriceDeformation
  ( EtaX96(..)
  , deformationLayout
  , plotDeformation
  , plotVarSigmaEta
  , pattern BASE_ETA
  )
import Greeks.Delta (deltaLayout)
import Greeks.Gamma (gammaLayout, kristensenGammaLayoutVsGamma)
import Payoffs.CPMMPosition (rhsPayoffLayout)
import Payoffs.VolatilityCall (mkVolStrike, volatilityCallLayout)
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
  , mkTickSpacing
  , pattern Q96
  )
import State
  ( pattern SQRT_PRICE_1_4
  , pattern SQRT_PRICE_4_1
  )
import TickPath (mkTickPath, tickPathLayout)
import Volatility.VolTermStructure (BarL(..), FlowVol(..), cevFromPhi)
import StrikeX96 (strike)

main :: IO ()
main = do
  createDirectoryIfMissing True "outputs/Pricing"
  createDirectoryIfMissing True "outputs/Payoffs"
  createDirectoryIfMissing True "outputs/Greeks"
  createDirectoryIfMissing True "outputs/Liquidity"
  createDirectoryIfMissing True "outputs/TickPath"

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
