module Trading.Quote
  ( Quote(..)
  , mkQuote
  , phiMFromQuote
  , phiXFromQuote
  ) where

import Payoffs.Linear (linearPayoff)
import Pricing.Stremia (FeePips, feePipsFromAsk, feePipsFromBid)
import SqrtGrid (SqrtPriceX96(..))

-- Executable mid + bid/ask sqrts. φ_M ← φ(ask), φ_X ← φ(bid).
data Quote = Quote
  { quoteMid :: SqrtPriceX96
  , quoteBid :: SqrtPriceX96
  , quoteAsk :: SqrtPriceX96
  }
  deriving (Show, Eq)

mkQuote :: SqrtPriceX96 -> SqrtPriceX96 -> SqrtPriceX96 -> Quote
mkQuote mid@(SqrtPriceX96 m) bid@(SqrtPriceX96 b) ask@(SqrtPriceX96 a)
  | m <= 0 || b <= 0 || a <= 0 =
      error "Trading.Quote.mkQuote: mid/bid/ask must be > 0"
  | b > m || a < m =
      error "Trading.Quote.mkQuote: need bid ≤ mid ≤ ask"
  | otherwise = Quote mid bid ask

phiMFromQuote :: Quote -> FeePips
phiMFromQuote (Quote mid _ ask) =
  feePipsFromAsk (linearPayoff mid) (linearPayoff ask)

phiXFromQuote :: Quote -> FeePips
phiXFromQuote (Quote mid bid _) =
  feePipsFromBid (linearPayoff mid) (linearPayoff bid)
