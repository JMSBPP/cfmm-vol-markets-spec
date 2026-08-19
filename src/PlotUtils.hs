{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}

module PlotUtils
  ( Panel(..)
  , writePanel
  , canvasSize
  ) where

import Data.Kind (Type)
import Data.Proxy (Proxy(..))
import GHC.TypeLits (KnownNat, Nat, natVal, type (+))
import qualified Graphics.Rendering.Chart.Grid as G
import Graphics.Rendering.Chart.Backend.Cairo
  ( FileOptions(..)
  , renderableToFile
  )
import Graphics.Rendering.Chart.Easy
  ( Layout
  , Renderable
  , def
  , fillBackground
  , layoutToRenderable
  )
import Graphics.Rendering.Chart.Layout (LayoutPick)

type LayoutPickD = LayoutPick Double Double Double

cellWidthPx :: Int
cellWidthPx = 900

cellHeightPx :: Int
cellHeightPx = 720

-- Rows and columns are in the type. Canvas size is natVal r/c, not length of a list.
data Panel :: Nat -> Nat -> Type where
  Cell   :: Layout Double Double -> Panel 1 1
  Vacant :: Panel 1 1
  Beside :: Panel r c1 -> Panel r c2 -> Panel r (c1 + c2)
  Above  :: Panel r1 c -> Panel r2 c -> Panel (r1 + r2) c

canvasSize :: forall r c. (KnownNat r, KnownNat c) => Panel r c -> (Int, Int)
canvasSize _ =
  ( fromInteger (natVal (Proxy @c)) * cellWidthPx
  , fromInteger (natVal (Proxy @r)) * cellHeightPx
  )

writePanel
  :: (KnownNat r, KnownNat c)
  => FilePath
  -> Panel r c
  -> IO ()
writePanel path panel = do
  _ <-
    renderableToFile
      def { _fo_size = canvasSize panel }
      path
      (fillBackground def (G.gridToRenderable (panelToGrid panel)))
  pure ()

panelToGrid :: Panel r c -> G.Grid (Renderable LayoutPickD)
panelToGrid (Cell layout) =
  stretch (G.tval (layoutToRenderable layout))
panelToGrid Vacant =
  stretch G.empty
panelToGrid (Beside left right) =
  stretch (G.beside (panelToGrid left) (panelToGrid right))
panelToGrid (Above top bottom) =
  stretch (G.above (panelToGrid top) (panelToGrid bottom))

stretch :: G.Grid a -> G.Grid a
stretch = G.weights (1, 1)
