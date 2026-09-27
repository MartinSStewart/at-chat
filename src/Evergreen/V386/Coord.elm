module Evergreen.V386.Coord exposing (..)

import Quantity


type alias Coord units =
    ( Quantity.Quantity Int units, Quantity.Quantity Int units )
