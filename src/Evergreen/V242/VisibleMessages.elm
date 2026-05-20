module Evergreen.V242.VisibleMessages exposing (..)

import Evergreen.V242.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V242.Id.Id messageId
    , count : Int
    }
