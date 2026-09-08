{-# LANGUAGE PackageImports #-}

module Main (main) where

import Control.Exception (IOException, try)
import HevmTickMathAdapter (getSqrtPriceAtTick)
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..))
import System.Exit (die)

main :: IO ()
main = do
  actual <-
    getSqrtPriceAtTick
      "evm/out/TickMathHarness.sol/TickMathHarness.json"
      (-887272)
  if actual == SqrtPriceX96 4295128739
    then pure ()
    else die $ "minimum tick mismatch: " <> show actual

  missing <-
    try
      ( getSqrtPriceAtTick
          "evm/out/TickMathHarness.sol/TickMathHarness.missing.json"
          (-887272)
      ) ::
      IO (Either IOException SqrtPriceX96)
  case missing of
    Left _ -> pure ()
    Right value -> die $ "missing artifact unexpectedly returned " <> show value
