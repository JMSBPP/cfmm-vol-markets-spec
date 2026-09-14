{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}

module HevmSqrtGrid
  ( TickMath (..)
  , TickMathHarness
  , asTickMath
  ) where

import Control.Monad.IO.Class (liftIO)
import qualified Data.Vector as Vector
import EVM.ABI (AbiValue (..))
import EVM.Solidity (SolcContract)
import Hevm (Hevm, Session, call, mkSession, requireNamedMethod)
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..), Tick)

data TickMathHarness

class TickMath m where
  getSqrtPriceAtTick :: Tick -> m SqrtPriceX96

asTickMath :: SolcContract -> IO (Session TickMathHarness)
asTickMath contract = do
  requireNamedMethod "getSqrtPriceAtTick" contract
  pure (mkSession contract)

instance TickMath (Hevm TickMathHarness) where
  getSqrtPriceAtTick tick = do
    values <-
      call
        "getSqrtPriceAtTick"
        (AbiTuple (Vector.singleton (AbiInt 24 (fromIntegral tick))))
    case values of
      [AbiUInt _ word] -> pure (SqrtPriceX96 (fromIntegral word))
      _ -> liftIO (ioError (userError "HevmSqrtGrid: unexpected ABI value"))
