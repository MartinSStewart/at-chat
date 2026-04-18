module Evergreen.V204.VisibleMessages exposing (..)

import Evergreen.V204.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V204.Id.Id messageId
    , count : Int
    }
