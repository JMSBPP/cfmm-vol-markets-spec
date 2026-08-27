{-# LANGUAGE PatternSynonyms #-}

module TickPath
  ( TickPath(..)
  , mkTickPath
  ) where

import Control.Monad.ST (runST)
import Data.Word (Word32)
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as MV
import qualified Data.Vector.Unboxed as VU
import Pricing.PriceDeformation (uniswapMinTick)
import SqrtGrid
  ( Tick
  , SqrtPriceX96(..)
  , pattern Q96
  , sqrtPrice
  , tickFromSqrtPriceX96
  )
import System.Random.MWC (initialize)
import System.Random.MWC.Distributions (standard)
import Volatility.VolTermStructure
  ( Step(..)
  , VolTermStructure(..)
  , unInstantaneousVol
  )

data TickPath = TickPath
  { pathLength :: Int
  , ticks      :: V.Vector Tick
  }
  deriving (Show, Eq)

mkTickPath
  :: Int
  -> VolTermStructure
  -> Word32
  -> Tick
  -> TickPath
mkTickPath n vts seed i0
  | n < 2 =
      error "TickPath.mkTickPath: N must be ≥ 2"
  | otherwise =
      TickPath n $ runST $ do
        gen <- initialize (VU.singleton seed)
        buf <- MV.new n
        MV.write buf 0 i0
        fill gen buf 0 i0
        V.freeze buf
  where
    pMin :: Double
    pMin = let p12 = sqrtPrice uniswapMinTick in p12 * p12

    fill gen buf t i
      | t >= n - 1 = pure ()
      | otherwise = do
          z <- standard gen
          let
            p12 = sqrtPrice i
            p = p12 * p12
            sigma = unInstantaneousVol (volAt vts i (Step t))
            mu = sigma * sigma * p / 4
            pNext = max pMin (p + mu + sigma * p * z)
            sqrtNext = sqrt pNext
            word =
              floor (sqrtNext * fromInteger Q96)
            iRaw = tickFromSqrtPriceX96 (SqrtPriceX96 word)
            iNext = max uniswapMinTick iRaw
          MV.write buf (t + 1) iNext
          fill gen buf (t + 1) iNext
