{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE TypeApplications #-}

module Hevm (Hevm, runHevm, callGetSqrtPriceAtTick) where

import Control.Lens (view)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Except (ExceptT, runExceptT, throwE)
import Control.Monad.Trans.Reader (ReaderT (..), ask)
import qualified Data.ByteString as BS
import Data.Generics.Product.Fields (field)
import Data.List (find)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Vector as Vector
import EVM.ABI
  ( AbiType
  , AbiVals (..)
  , AbiValue (..)
  , abiMethod
  , decodeBuf
  )
import EVM.Solidity (Method, SolcContract)
import EVM.Types (EvmError, Expr (ConcreteBuf))
import HevmExec (execRuntime)
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..), Tick)

newtype Hevm a = Hevm (ExceptT EvmError (ReaderT SolcContract IO) a)
  deriving newtype (Functor, Applicative, Monad, MonadIO)

runHevm :: SolcContract -> Hevm a -> IO (Either EvmError a)
runHevm contract (Hevm action) =
  runReaderT (runExceptT action) contract

callGetSqrtPriceAtTick :: Tick -> Hevm SqrtPriceX96
callGetSqrtPriceAtTick tick = Hevm $ do
  contract <- lift ask
  method <-
    liftIO $
      maybe
        (ioError (userError "Hevm: missing method getSqrtPriceAtTick"))
        pure
        (lookupMethod contract "getSqrtPriceAtTick")
  let callData =
        abiMethod
          (view (field @"methodSignature") method)
          (AbiTuple (Vector.singleton (AbiInt 24 (fromIntegral tick))))
  liftIO (execRuntime (view (field @"runtimeCode") contract) callData) >>= \case
    Left evmError -> throwE evmError
    Right bytes ->
      case decodeUint160 (snd <$> view (field @"output") method) bytes of
        Left err -> liftIO (ioError (userError ("Hevm: " <> err)))
        Right price -> pure price

lookupMethod :: SolcContract -> Text -> Maybe Method
lookupMethod contract wanted =
  find
    (\method -> view (field @"name") method == wanted)
    (Map.elems (view (field @"abiMap") contract))

decodeUint160 :: [AbiType] -> BS.ByteString -> Either String SqrtPriceX96
decodeUint160 types bytes =
  case decodeBuf types (ConcreteBuf bytes) of
    (CAbi [AbiUInt _ word], _) -> Right (SqrtPriceX96 (fromIntegral word))
    (CAbi _, err) -> Left ("unexpected ABI value" <> suffix err)
    (NoVals, err) -> Left ("ABI decode failed" <> suffix err)
    (SAbi _, _) -> Left "symbolic ABI output"
  where
    suffix err
      | null err = ""
      | otherwise = ": " <> err
