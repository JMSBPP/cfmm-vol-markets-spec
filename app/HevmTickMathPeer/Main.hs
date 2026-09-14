{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PackageImports #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main (main) where

import Control.Concurrent (threadDelay)
import Control.Exception (IOException, SomeException, catch, displayException, try)
import Control.Monad (when)
import Data.Aeson
  ( FromJSON (parseJSON)
  , Value (Array, Number, Null)
  , eitherDecodeStrict'
  , encode
  , object
  , withObject
  , (.:)
  , (.:?)
  , (.!=)
  , (.=)
  )
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import qualified Data.ByteString.Lazy as BL
import qualified Data.Map as Map
import Data.Scientific (floatingOrInteger)
import Data.Text (Text)
import qualified Data.Text as Text
import Data.Text.Encoding (decodeUtf8)
import qualified Data.Vector as Vector
import EVM.Solidity (ProjectType (Foundry), SolcContract, getContractsMap, readJSON)
import EVM.Types (EvmError)
import qualified HevmSqrtGrid
import Network.Socket
  ( Family (AF_UNIX)
  , SockAddr (SockAddrUnix)
  , Socket
  , SocketType (Stream)
  , connect
  , defaultProtocol
  , socket
  , socketToHandle
  )
import "cfmm-vol-markets-spec" SqrtGrid (SqrtPriceX96 (..))
import System.Environment (getArgs, lookupEnv)
import System.Exit (die)
import System.FilePath (takeBaseName)
import System.IO
  ( BufferMode (LineBuffering)
  , IOMode (ReadWriteMode)
  , hFlush
  , hSetBuffering
  )
import Text.Read (readMaybe)

data RpcRequest = RpcRequest
  { requestId :: Value
  , requestMethod :: Text
  , requestParams :: Value
  }

instance FromJSON RpcRequest where
  parseJSON =
    withObject "RpcRequest" $ \request ->
      RpcRequest
        <$> request .: "id"
        <*> request .: "method"
        <*> (request .:? "params" .!= Null)

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["--probe", tickText, "--artifact", artifactPath] -> runProbe tickText artifactPath
    _ -> do
      artifactPath <-
        maybe
          (die "hevm-tickmath-peer: missing --artifact PATH")
          pure
          (flagValue "--artifact" args)
      socketPath <- resolveSocket args
      maybe
        (die "hevm-tickmath-peer: missing --sock PATH or RELAY_SOCK")
        (`runPeer` artifactPath)
        socketPath

runProbe :: String -> FilePath -> IO ()
runProbe tickText artifactPath =
  case readMaybe tickText of
    Nothing -> die "hevm-tickmath-peer: probe tick must be an integer"
    Just tick
      | not (inInt24Range tick) ->
          die "hevm-tickmath-peer: probe tick outside signed int24 range"
      | otherwise -> do
          contract <- loadForgeContract artifactPath
          outcome <- HevmSqrtGrid.getSqrtPriceAtTick contract tick
          case outcome of
            Left evmError ->
              die ("hevm-tickmath-peer: EVM failure: " <> show evmError)
            Right (SqrtPriceX96 result) -> print result

resolveSocket :: [String] -> IO (Maybe FilePath)
resolveSocket args =
  case flagValue "--sock" args of
    Just path -> pure (Just path)
    Nothing -> lookupEnv "RELAY_SOCK"

flagValue :: String -> [String] -> Maybe String
flagValue _ [] = Nothing
flagValue flag (candidate : value : rest)
  | candidate == flag = Just value
  | otherwise = flagValue flag (value : rest)
flagValue _ [_] = Nothing

loadForgeContract :: FilePath -> IO SolcContract
loadForgeContract artifactPath = do
  json <- decodeUtf8 <$> BS.readFile artifactPath
  case readJSON Foundry (Text.pack (takeBaseName artifactPath)) json of
    Left err ->
      die ("hevm-tickmath-peer: Foundry artifact load failed: " <> show err)
    Right (contracts, _, _) ->
      case Map.elems (getContractsMap contracts) of
        [loaded] -> pure loaded
        loaded ->
          die
            ( "hevm-tickmath-peer: expected one contract in artifact, got "
                <> show (length loaded)
            )

runPeer :: FilePath -> FilePath -> IO ()
runPeer socketPath artifactPath = do
  contract <- loadForgeContract artifactPath
  sock <- connectRetrying socketPath 50
  handle <- socketToHandle sock ReadWriteMode
  hSetBuffering handle LineBuffering
  let loop = do
        input <- try (BSC.hGetLine handle) :: IO (Either IOException BS.ByteString)
        case input of
          Left _ -> pure ()
          Right requestLine -> do
            response <- dispatch contract requestLine
            (BL.hPut handle (encode response) >> BSC.hPutStr handle "\n" >> hFlush handle)
              `catch` \(_ :: IOException) -> pure ()
            loop
  loop

dispatch :: SolcContract -> BS.ByteString -> IO Value
dispatch contract requestLine =
  case eitherDecodeStrict' requestLine of
    Left decodeError ->
      pure (rpcError Null (-32700 :: Int) ("parse error: " <> Text.pack decodeError))
    Right request
      | requestMethod request /= "getSqrtPriceAtTick" ->
          pure (rpcError (requestId request) (-32601 :: Int) "method not found")
      | otherwise ->
          case singletonInt24 (requestParams request) of
            Left paramsError ->
              pure (rpcError (requestId request) (-32602 :: Int) paramsError)
            Right tick -> do
              result <-
                try (HevmSqrtGrid.getSqrtPriceAtTick contract tick) ::
                  IO (Either SomeException (Either EvmError SqrtPriceX96))
              pure $
                case result of
                  Left err ->
                    rpcError
                      (requestId request)
                      (-32000 :: Int)
                      (Text.pack (displayException err))
                  Right (Left evmError) ->
                    rpcError
                      (requestId request)
                      (-32000 :: Int)
                      (Text.pack (show evmError))
                  -- Emit a JSON *string* so Foundry `vm.ffi` does not hex-decode a
                  -- digit-only decimal (e.g. 4295128739 → 5 raw bytes).
                  Right (Right (SqrtPriceX96 value)) ->
                    object
                      [ "jsonrpc" .= ("2.0" :: Text)
                      , "id" .= requestId request
                      , "result" .= Text.pack (show value)
                      ]

singletonInt24 :: Value -> Either Text Int
singletonInt24 (Array values) =
  case Vector.toList values of
    [Number scientific] ->
      case floatingOrInteger scientific :: Either Double Integer of
        Right value
          | value >= fromIntegral minInt24 && value <= fromIntegral maxInt24 ->
              Right (fromIntegral value)
        _ -> Left "params must contain one signed int24 integer"
    _ -> Left "params must contain one signed int24 integer"
singletonInt24 _ = Left "params must contain one signed int24 integer"

rpcError :: Value -> Int -> Text -> Value
rpcError rid code message =
  object
    [ "jsonrpc" .= ("2.0" :: Text)
    , "id" .= rid
    , "error"
        .= object
          [ "code" .= code
          , "message" .= message
          ]
    ]

connectRetrying :: FilePath -> Int -> IO Socket
connectRetrying path attempts = do
  when (attempts <= 0) $
    die ("hevm-tickmath-peer: could not connect to " <> path)
  result <-
    try
      ( do
          sock <- socket AF_UNIX Stream defaultProtocol
          connect sock (SockAddrUnix path)
          pure sock
      ) ::
      IO (Either IOException Socket)
  case result of
    Right sock -> pure sock
    Left _ -> threadDelay 100000 >> connectRetrying path (attempts - 1)

inInt24Range :: Int -> Bool
inInt24Range tick = tick >= minInt24 && tick <= maxInt24

minInt24, maxInt24 :: Int
minInt24 = -8388608
maxInt24 = 8388607
