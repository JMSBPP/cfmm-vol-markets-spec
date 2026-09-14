{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Hevm
  ( Hevm
  , Session
  , mkSession
  , runHevm
  , call
  , requireNamedMethod
  ) where

import Control.Lens (view)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.Trans.Class (lift)
import Control.Monad.Trans.Except (ExceptT, runExceptT, throwE)
import Control.Monad.Trans.Reader (ReaderT (..), ask)
import Data.Kind (Type)
import Data.List (find)
import qualified Data.Map as Map
import Data.Text (Text)
import qualified Data.Text as Text
import Data.Generics.Product.Fields (field)
import EVM.ABI
  ( AbiVals (..)
  , AbiValue
  , abiMethod
  , decodeBuf
  )
import EVM.Solidity (Method, SolcContract)
import EVM.Types (EvmError, Expr (ConcreteBuf))
import HevmExec (execRuntime)

newtype Session (c :: Type) = Session SolcContract

newtype Hevm (c :: Type) a = Hevm (ExceptT EvmError (ReaderT (Session c) IO) a)
  deriving newtype (Functor, Applicative, Monad, MonadIO)

mkSession :: SolcContract -> Session c
mkSession = Session

runHevm :: Session c -> Hevm c a -> IO (Either EvmError a)
runHevm session (Hevm action) =
  runReaderT (runExceptT action) session

requireNamedMethod :: Text -> SolcContract -> IO ()
requireNamedMethod name contract =
  maybe
    (ioError (userError ("Hevm: missing method " <> Text.unpack name)))
    (\_ -> pure ())
    (lookupMethod contract name)

call :: Text -> AbiValue -> Hevm c [AbiValue]
call name args = Hevm $ do
  Session contract <- lift ask
  method <-
    liftIO $
      maybe
        (ioError (userError ("Hevm: missing method " <> Text.unpack name)))
        pure
        (lookupMethod contract name)
  let callData = abiMethod (view (field @"methodSignature") method) args
  liftIO (execRuntime (view (field @"runtimeCode") contract) callData) >>= \case
    Left evmError -> throwE evmError
    Right bytes ->
      case decodeBuf (snd <$> view (field @"output") method) (ConcreteBuf bytes) of
        (CAbi values, _) -> pure values
        (NoVals, err) ->
          liftIO (ioError (userError ("Hevm: ABI decode failed" <> suffix err)))
        (SAbi _, _) ->
          liftIO (ioError (userError "Hevm: symbolic ABI output"))
  where
    suffix err
      | null err = ""
      | otherwise = ": " <> err

lookupMethod :: SolcContract -> Text -> Maybe Method
lookupMethod contract wanted =
  find
    (\method -> view (field @"name") method == wanted)
    (Map.elems (view (field @"abiMap") contract))
