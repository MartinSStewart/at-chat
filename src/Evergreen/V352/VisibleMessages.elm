module Evergreen.V352.VisibleMessages exposing (..)

import Evergreen.V352.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V352.Id.Id messageId
    , count : Int
    }
