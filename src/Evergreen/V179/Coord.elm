module Evergreen.V179.Coord exposing (..)

import Quantity


type alias Coord units =
    ( Quantity.Quantity Int units, Quantity.Quantity Int units )
