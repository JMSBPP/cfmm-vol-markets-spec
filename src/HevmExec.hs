{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE NumericUnderscores #-}

module HevmExec (execRuntime) where

import Control.Monad.ST (stToIO)
import qualified Data.ByteString as BS
import Data.Word (Word64)
import qualified EVM
import qualified EVM.Effects as Effects
import qualified EVM.Fetch as Fetch
import qualified EVM.Solvers as Solvers
import qualified EVM.Stepper as Stepper
import qualified EVM.Transaction as Transaction
import qualified EVM.Types as Types

execRuntime :: BS.ByteString -> BS.ByteString -> IO (Either Types.EvmError BS.ByteString)
execRuntime runtimeCode callData = do
  let contract = EVM.initialContract (Types.RuntimeCode (Types.ConcreteRuntimeCode runtimeCode))
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
  case result of
    Left evmError -> pure (Left evmError)
    Right (Types.ConcreteBuf bytes) -> pure (Right bytes)
    Right _ ->
      ioError (userError "HevmExec: non-concrete EVM output")

executionGasLimit :: Word64
executionGasLimit = 30_000_000
