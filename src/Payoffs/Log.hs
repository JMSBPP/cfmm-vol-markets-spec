{-# LANGUAGE PatternSynonyms #-}

-- | Log contract on the sqrt grid, with a CONTINUOUS integer log (TODO #28
-- item 1).  `nakedLogQ96 p p*` = ln(p/p*) in Q96 = 2·ln(p½/p½*), computed as
--
--   x = mulDiv(p½, WAD, p½*)            (WAD-scaled sqrt-price ratio)
--   l = lnWad x                          (Solady FixedPointMathLib.lnWad, WAD)
--   nakedLogQ96 = floor(2·l·Q96 / WAD)   (signed: Haskell `div` floors)
--
-- `lnWad` is a line-by-line port of Solady's (8,8)-term rational
-- approximation: `sar` ↦ arithmetic shift (`shiftR` on Integer floors),
-- `sdiv` ↦ `quot` (truncates toward zero), all in unbounded Integer (the EVM
-- twin is int256; every intermediate stays below 2^255 for x < 2^255).
-- Error: Solady states "approximation, monotonically increasing" and gives no
-- bound; the test suite MEASURES it (docs/BITWIDTHS.md).  The previous
-- tick-quantized version is kept as `nakedLogTickQ96` for regression only:
-- its error is ≤ ½·ln(1.0001) ≈ 5e-5 absolute in ln(p/p*).
module Payoffs.Log
  ( nakedLogQ96
  , nakedLogTickQ96
  , lnWad
  , lnQ96
  , logPortfolioQ96
  , pattern WAD
  , payoff
  , logContract
  ) where

import Data.Bits (shiftL, shiftR, xor, (.&.), (.|.))

import qualified Payoffs.Payoff as Payoff
import Payoffs.Forward (AtmForward(..), nakedForwardQ96, unAtmForward)
import Panoptic.NId (NId, scaleByNId)
import SqrtGrid
  ( SqrtPriceX96(..)
  , PayoffX96(..)
  , mulDiv
  , pattern Q96
  , tickBase
  , tickFromSqrtPriceX96
  )

pattern WAD :: Integer
pattern WAD = 1000000000000000000

-- | Solady `lnWad`: ln(x) for x in WAD, result in WAD.  x must be > 0.
lnWad :: Integer -> Integer
lnWad x0
  | x0 <= 0 = error "Payoffs.Log.lnWad: undefined for x <= 0"
  | otherwise =
      let
        -- r = 255 ^ log2(x)  (branchless MSB search, as in the assembly)
        lt a b = if a < b then 1 else 0 :: Integer
        r1 = lt 0xffffffffffffffffffffffffffffffff x0 `shiftL` 7
        r2 = r1 .|. (lt 0xffffffffffffffff (x0 `shiftR` fromInteger r1) `shiftL` 6)
        r3 = r2 .|. (lt 0xffffffff (x0 `shiftR` fromInteger r2) `shiftL` 5)
        r4 = r3 .|. (lt 0xffff (x0 `shiftR` fromInteger r3) `shiftL` 4)
        r5 = r4 .|. (lt 0xff (x0 `shiftR` fromInteger r4) `shiftL` 3)
        deBruijnIdx = (0x8421084210842108cc6318c6db6d54be `shiftR` fromInteger (x0 `shiftR` fromInteger r5)) .&. 0x1f
        tbl = 0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff :: Integer
        byteAt i w = (w `shiftR` (8 * (31 - fromInteger i))) .&. 0xff   -- EVM `byte(i, w)`
        r  = r5 `xor` byteAt deBruijnIdx tbl
        -- reduce x to (1, 2) * 2^96
        x  = (x0 `shiftL` fromInteger r) `shiftR` 159
        sar96 v = v `shiftR` 96
        p0 = sar96 ((3273285459638523848632254066296 + x) * x)
        p1 = sar96 ((24828157081833163892658089445524 + p0) * x)
        p2 = sar96 ((43456485725739037958740375743393 + p1) * x) - 11111509109440967052023855526967
        p3 = sar96 (p2 * x) - 45023709667254063763336534515857
        p4 = sar96 (p3 * x) - 14706773417378608786704636184526
        p5 = p4 * x - (795164235651350426258249787498 `shiftL` 96)
        q0 = 5573035233440673466300451813936 + x
        q1 = 71694874799317883764090561454958 + sar96 (x * q0)
        q2 = 283447036172924575727196451306956 + sar96 (x * q1)
        q3 = 401686690394027663651624208769553 + sar96 (x * q2)
        q4 = 204048457590392012362485061816622 + sar96 (x * q3)
        q5 = 31853899698501571402653359427138 + sar96 (x * q4)
        q6 = 909429971244387300277376558375 + sar96 (x * q5)
        pq = p5 `quot` q6                                            -- sdiv
        s1 = 1677202110996718588342820967067443963516166 * pq
        s2 = 16597577552685614221487285958193947469193820559219878177908093499208371 * (159 - r) + s1
        s3 = 600920179829731861736702779321621459595472258049074101567377883020018308 + s2
      in
        s3 `shiftR` 174                                              -- sar(174, p)

-- | ln(p/p*) = 2·ln(p½/p½*), Q96-scaled, floor.
lnQ96 :: SqrtPriceX96 -> SqrtPriceX96 -> PayoffX96
lnQ96 (SqrtPriceX96 p) (SqrtPriceX96 pStar)
  | pStar <= 0 || p <= 0 = error "Payoffs.Log.lnQ96: sqrt prices must be > 0"
  | otherwise =
      let x = mulDiv p WAD pStar
          l = lnWad x
      in  PayoffX96 (mulDiv (2 * l) Q96 WAD)

nakedLogQ96 :: SqrtPriceX96 -> AtmForward -> PayoffX96
nakedLogQ96 spot atm = lnQ96 spot (unAtmForward atm)

-- | Tick-quantized log (pre-#28.1), regression reference only.
nakedLogTickQ96 :: SqrtPriceX96 -> AtmForward -> PayoffX96
nakedLogTickQ96 spot atm =
  let
    i = tickFromSqrtPriceX96 spot
    iStar = tickFromSqrtPriceX96 (unAtmForward atm)
  in
    PayoffX96 $
      floor
        ( fromIntegral Q96
            * fromIntegral (i - iStar)
            * log tickBase
        )

payoff :: NId -> SqrtPriceX96 -> AtmForward -> PayoffX96
payoff nId spot atm =
  let PayoffX96 naked = nakedLogQ96 spot atm
  in  PayoffX96 (scaleByNId nId naked)

logContract :: NId -> AtmForward -> Payoff.Payoff SqrtPriceX96
logContract nId atm =
  Payoff.Payoff (\spot -> payoff nId spot atm)

-- | T0 bare: logPortfolio(P, P*) = (P − P*)/P* − ln(P/P*) in Q96, continuous log.
-- The single definition of the Carr–Madan / Demeterfi log portfolio in this
-- codebase (README § REPLICATION_THEORY Def 7; Lean VolInstrument.logPortfolio).
-- VariancePortfolio (T0 with N_id scale and R) is built from this.
logPortfolioQ96 :: SqrtPriceX96 -> SqrtPriceX96 -> PayoffX96
logPortfolioQ96 p pStar =
  let PayoffX96 f = nakedForwardQ96 p (AtmForward pStar)
      PayoffX96 l = lnQ96 p pStar
  in  PayoffX96 (f - l)
