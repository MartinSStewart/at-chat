module Evergreen.V192.VisibleMessages exposing (..)

import Evergreen.V192.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V192.Id.Id messageId
    , count : Int
    }
