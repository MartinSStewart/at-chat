module Evergreen.V273.VisibleMessages exposing (..)

import Evergreen.V273.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V273.Id.Id messageId
    , count : Int
    }
