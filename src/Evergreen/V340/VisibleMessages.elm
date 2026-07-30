module Evergreen.V340.VisibleMessages exposing (..)

import Evergreen.V340.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V340.Id.Id messageId
    , count : Int
    }
