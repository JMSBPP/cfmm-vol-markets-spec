-- | Adaptive (volatility) fee — integer-exact port of Algebra's @AdaptiveFee.sol@
-- (@cryptoalgebra/algebra-plugins@, AlgebraBasePluginV1; BUSL-1.1), TODO #9 / #5.
--
--   getFee(σ) = baseFee + Σ_{j=1,2} α_j / (1 + e^{(β_j − σ/15)/γ_j})           (pips, uint16)
--
-- with @sigmoid@ / @expXg4@ reproduced step by step (branch on x > β, the 6γ cut-off,
-- the e^k table at 1e20, the e^{1/2} shift, the 4th-order series in g^4 units) so the
-- Haskell value IS the on-chain value.  Units: fee in pips (1e-6, the FeePips scale =
-- Algebra's "hundredths of a bip"); volatility in Algebra's oracle units (uint88,
-- time-average of squared tick deviation over the window; getFee divides by 15).
--
-- Θ_φ of README § "adaptive markup φ(Θ_φ; σ², ν)" is 'AdaptiveStremia' (the 7-field
-- config); the ν argument (volume sigmoid) existed only in Algebra V1's older
-- @getFee(volatility, volumePerLiquidity, config)@ and is dropped in this version.
module Pricing.AdaptiveStremia
  ( AdaptiveStremia(..)
  , initialFeeConfiguration
  , validateFeeConfiguration
  , Volatility(..)
  , adaptiveFeePips
  , sigmoid
  , expXg4
  , pathVolatility
  ) where

import Pricing.Stremia (FeePips, mkFeePips)
import SqrtGrid (Tick)

-- | @AlgebraFeeConfiguration@: α_j, β_j, γ_j, baseFee (uint16/uint32/uint16/uint16).
data AdaptiveStremia = AdaptiveStremia
  { alpha1  :: Integer   -- uint16, max of sigmoid 1 (pips)
  , alpha2  :: Integer   -- uint16
  , beta1   :: Integer   -- uint32, x-shift (volatility units)
  , beta2   :: Integer   -- uint32
  , gamma1  :: Integer   -- uint16, horizontal stretch
  , gamma2  :: Integer   -- uint16
  , baseFee :: Integer   -- uint16 (pips)
  }
  deriving (Show, Eq)

initialMinFee :: Integer
initialMinFee = 100   -- 0.01e4 = 0.01 %

-- | @AdaptiveFee.initialFeeConfiguration@.
initialFeeConfiguration :: AdaptiveStremia
initialFeeConfiguration = AdaptiveStremia
  { alpha1 = 3000 - initialMinFee, alpha2 = 15000 - 3000
  , beta1 = 360, beta2 = 60000, gamma1 = 59, gamma2 = 8500, baseFee = initialMinFee }

-- | @validateFeeConfiguration@: α1 + α2 + baseFee ≤ uint16 max, γ ≠ 0 (plus the field widths).
validateFeeConfiguration :: AdaptiveStremia -> Either String AdaptiveStremia
validateFeeConfiguration c
  | alpha1 c + alpha2 c + baseFee c > 65535 = Left "Max fee exceeded"
  | gamma1 c == 0 || gamma2 c == 0          = Left "Gammas must be > 0"
  | any (\x -> x < 0 || x > 65535) [alpha1 c, alpha2 c, gamma1 c, gamma2 c, baseFee c] = Left "uint16 field out of range"
  | any (\x -> x < 0 || x > 4294967295) [beta1 c, beta2 c] = Left "uint32 field out of range"
  | otherwise = Right c

-- | Algebra oracle volatility (uint88).
newtype Volatility = Volatility Integer
  deriving (Show, Eq, Ord)

-- | @getFee@: baseFee + sigmoid1 + sigmoid2 after @volatility /= 15@.
adaptiveFeePips :: AdaptiveStremia -> Volatility -> FeePips
adaptiveFeePips c (Volatility v)
  | v < 0 || v >= 2 ^ (88 :: Int) = error "Pricing.AdaptiveStremia.adaptiveFeePips: volatility must fit uint88"
  | otherwise =
      let x = v `div` 15
          s = sigmoid x (gamma1 c) (alpha1 c) (beta1 c) + sigmoid x (gamma2 c) (alpha2 c) (beta2 c)
          r = baseFee c + s
      in  if r > 65535 then error "Pricing.AdaptiveStremia.adaptiveFeePips: fee exceeds uint16" else mkFeePips r

-- | @sigmoid(x, g, alpha, beta)@ = α / (1 + e^{(β − x)/γ}), integer, ≤ α.
sigmoid :: Integer -> Integer -> Integer -> Integer -> Integer
sigmoid x g alpha beta
  | x > beta =
      let d = x - beta
      in  if d >= 6 * g then alpha
          else let g4 = g ^ (4 :: Int); ex = expXg4 d g g4 in (alpha * ex) `div` (g4 + ex)
  | otherwise =
      let d = beta - x
      in  if d >= 6 * g then 0
          else let g4 = g ^ (4 :: Int); ex = g4 + expXg4 d g g4 in (alpha * g4) `div` ex

-- | @expXg4(x, g, g^4)@ = e^{x/g} · g^4: table value e^{⌊x/g⌋} (×1e20), optional e^{1/2}
-- shift, then the 4th-order series on the remainder in g^4 units.  Exact port.
expXg4 :: Integer -> Integer -> Integer -> Integer
expXg4 x0 g gHigh0 =
  let xdg = x0 `div` g
      closest0 = case xdg of
        0 -> 100000000000000000000
        1 -> 271828182845904523536
        2 -> 738905609893065022723
        3 -> 2008553692318766774092
        4 -> 5459815003314423907811
        _ -> 14841315910257660342111
      x1 = x0 `mod` g
      (x, closest) = if x1 >= g `div` 2
                       then (x1 - g `div` 2, (closest0 * 164872127070012814684) `div` 100000000000000000000)
                       else (x1, closest0)
      g3 = gHigh0 `div` g
      g2 = g3 `div` g
      x2 = x * x
      x3 = x2 * x
      res0 = gHigh0
      res1 = res0 + x * g3
      res2 = res1 + (x2 * g2) `div` 2
      res3 = res2 + (x3 * g * 4 + x3 * x) `div` 24
  in  (res3 * closest) `div` 100000000000000000000

-- | Oracle-style volatility of a tick window: time-average of the squared deviation from the
-- window's mean tick, each sample weighted by @dt@ seconds (Algebra's volatilityCumulative /
-- window, tick² units; getFee then divides by 15).  Empty window → 0.
pathVolatility :: Integer -> [Tick] -> Volatility
pathVolatility dt ticks
  | null ticks || dt <= 0 = Volatility 0
  | otherwise =
      let n = toInteger (length ticks)
          s = sum (map toInteger ticks)
          -- mean tick rounded toward −∞; deviations squared in integer arithmetic
          m = s `div` n
          sq = sum [ (toInteger i - m) ^ (2 :: Int) | i <- ticks ]
      in  Volatility ((sq * dt) `div` (n * dt))
