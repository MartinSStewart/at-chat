module Evergreen.V243.VisibleMessages exposing (..)

import Evergreen.V243.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V243.Id.Id messageId
    , count : Int
    }
