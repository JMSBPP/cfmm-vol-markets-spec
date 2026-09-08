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
import Data.Scientific (floatingOrInteger)
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Vector as Vector
import HevmTickMathAdapter (getSqrtPriceAtTick)
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
          SqrtPriceX96 result <- getSqrtPriceAtTick artifactPath tick
          print result

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

runPeer :: FilePath -> FilePath -> IO ()
runPeer socketPath artifactPath = do
  sock <- connectRetrying socketPath 50
  handle <- socketToHandle sock ReadWriteMode
  hSetBuffering handle LineBuffering
  loop handle
  where
    loop handle = do
      input <- try (BSC.hGetLine handle) :: IO (Either IOException BS.ByteString)
      case input of
        Left _ -> pure ()
        Right requestLine -> do
          response <- dispatch artifactPath requestLine
          (BL.hPut handle (encode response) >> BSC.hPutStr handle "\n" >> hFlush handle)
            `catch` \(_ :: IOException) -> pure ()
          loop handle

dispatch :: FilePath -> BS.ByteString -> IO Value
dispatch artifactPath requestLine =
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
                try (getSqrtPriceAtTick artifactPath tick) ::
                  IO (Either SomeException SqrtPriceX96)
              pure $
                case result of
                  Left err ->
                    rpcError
                      (requestId request)
                      (-32000 :: Int)
                      (Text.pack (displayException err))
                  -- Emit a JSON *string* so Foundry `vm.ffi` does not hex-decode a
                  -- digit-only decimal (e.g. 4295128739 → 5 raw bytes).
                  Right (SqrtPriceX96 value) ->
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
