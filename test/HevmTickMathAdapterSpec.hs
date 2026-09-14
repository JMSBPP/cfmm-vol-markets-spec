{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}

module Main (main) where

import qualified Data.ByteString as BS
import qualified Data.Map as Map
import qualified Data.Text as Text
import Data.Text.Encoding (decodeUtf8)
import EVM.Solidity (ProjectType (Foundry), getContractsMap, readJSON)
import qualified HevmSqrtGrid
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..))
import System.Exit (die)
import System.FilePath (takeBaseName)

main :: IO ()
main = do
  json <- decodeUtf8 <$> BS.readFile harnessArtifact
  contract <-
    case readJSON Foundry (Text.pack (takeBaseName harnessArtifact)) json of
      Left err ->
        die ("HevmSqrtGrid: Foundry artifact load failed: " <> show err)
      Right (contracts, _, _) ->
        case Map.elems (getContractsMap contracts) of
          [loaded] -> pure loaded
          loaded ->
            die
              ( "HevmSqrtGrid: expected one contract in artifact, got "
                  <> show (length loaded)
              )
  actual <- HevmSqrtGrid.getSqrtPriceAtTick contract (-887272)
  case actual of
    Right price
      | price == SqrtPriceX96 4295128739 -> pure ()
    other -> die $ "HevmSqrtGrid minimum tick mismatch: " <> show other

  -- int24-legal, Uniswap-illegal: bytecode must reject (no Haskell MIN/MAX).
  outOfRange <- HevmSqrtGrid.getSqrtPriceAtTick contract 887273
  case outOfRange of
    Left _ -> pure ()
    Right price ->
      die $ "HevmSqrtGrid out-of-range tick unexpectedly returned " <> show price

harnessArtifact :: FilePath
harnessArtifact = "evm/out/TickMathHarness.sol/TickMathHarness.json"
