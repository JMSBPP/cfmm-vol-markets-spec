{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}

module HevmTickMathAdapter (getSqrtPriceAtTick) where

import Control.Monad (unless)
import Control.Monad.ST (stToIO)
import Data.Aeson (Value, eitherDecodeStrict', withObject, (.:))
import Data.Aeson.Types (Parser, parseEither)
import Data.Bits (shiftR)
import qualified Data.ByteString as BS
import Data.Char (digitToInt, isHexDigit)
import qualified Data.Text as Text
import Data.Word (Word64)
import qualified EVM
import qualified EVM.Effects as Effects
import qualified EVM.Fetch as Fetch
import qualified EVM.Solvers as Solvers
import qualified EVM.Stepper as Stepper
import qualified EVM.Transaction as Transaction
import qualified EVM.Types as Types
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..), Tick)

getSqrtPriceAtTick :: FilePath -> Tick -> IO SqrtPriceX96
getSqrtPriceAtTick artifactPath tick = do
  unless (tick >= minInt24 && tick <= maxInt24) $
    ioError (userError "HevmTickMathAdapter: tick outside signed int24 range")
  artifactBytes <- BS.readFile artifactPath
  artifact <-
    either
      (ioError . userError . ("HevmTickMathAdapter: invalid artifact: " <>))
      pure
      (eitherDecodeStrict' artifactBytes :: Either String Value)
  runtimeHex <-
    either
      (ioError . userError . ("HevmTickMathAdapter: missing deployed bytecode: " <>))
      pure
      (parseEither parseRuntime artifact)
  runtimeCode <-
    either
      (ioError . userError . ("HevmTickMathAdapter: invalid deployed bytecode: " <>))
      pure
      (decodeHex runtimeHex)

  let callData = selector <> encodeSignedWord tick
      contract = EVM.initialContract (Types.RuntimeCode (Types.ConcreteRuntimeCode runtimeCode))
      baseOpts = EVM.defaultVMOpts :: Types.VMOpts 'Types.Concrete
      opts :: Types.VMOpts 'Types.Concrete
      opts =
        baseOpts
          { Types.contract = contract
          , Types.calldata = (Types.ConcreteBuf callData, [])
          , Types.gas = Types.toGas executionGasLimit
          , Types.gaslimit = executionGasLimit
          }
  initialVm <- stToIO (EVM.makeVm opts)
  let initializedVm = Transaction.initTx initialVm
      fetcher = Fetch.zero 0 Nothing Solvers.defMemLimit
  result <- Effects.runApp (Stepper.interpret fetcher initializedVm Stepper.execFully)
  output <-
    case result of
      Left evmError ->
        ioError (userError ("HevmTickMathAdapter: EVM failure: " <> show evmError))
      Right (Types.ConcreteBuf bytes)
        | BS.length bytes == 32 -> pure bytes
        | otherwise ->
            ioError
              ( userError
                  ( "HevmTickMathAdapter: expected 32 output bytes, got "
                      <> show (BS.length bytes)
                  )
              )
      Right _ ->
        ioError (userError "HevmTickMathAdapter: non-concrete EVM output")

  let value = bytesToInteger output
  unless (value <= uint160Max) $
    ioError (userError "HevmTickMathAdapter: EVM output exceeds uint160")
  pure (SqrtPriceX96 value)

parseRuntime :: Value -> Parser Text.Text
parseRuntime = withObject "Forge artifact" $ \artifact -> do
  deployed <- artifact .: "deployedBytecode"
  withObject "deployedBytecode" (.: "object") deployed

decodeHex :: Text.Text -> Either String BS.ByteString
decodeHex encoded
  | null digits = Left "empty hex string"
  | odd (length digits) = Left "odd-length hex string"
  | not (all isHexDigit digits) = Left "non-hex digit"
  | otherwise = Right (BS.pack (pairs digits))
  where
    raw = Text.unpack encoded
    digits =
      case raw of
        '0' : 'x' : rest -> rest
        _ -> raw
    pairs [] = []
    pairs (hi : lo : rest) =
      fromIntegral (digitToInt hi * 16 + digitToInt lo) : pairs rest
    pairs _ = error "decodeHex: guarded odd-length input"

encodeSignedWord :: Tick -> BS.ByteString
encodeSignedWord tick =
  BS.pack
    [ fromIntegral ((word `shiftR` shift) `mod` 256)
    | shift <- [248, 240 .. 0]
    ]
  where
    word
      | tick < 0 = (2 :: Integer) ^ (256 :: Int) + fromIntegral tick
      | otherwise = fromIntegral tick

bytesToInteger :: BS.ByteString -> Integer
bytesToInteger = foldl' (\acc byte -> acc * 256 + fromIntegral byte) 0 . BS.unpack

selector :: BS.ByteString
selector = BS.pack [0x81, 0x47, 0xb1, 0x3b]

executionGasLimit :: Word64
executionGasLimit = 30_000_000

minInt24, maxInt24 :: Tick
minInt24 = -8_388_608
maxInt24 = 8_388_607

uint160Max :: Integer
uint160Max = (2 :: Integer) ^ (160 :: Int) - 1
