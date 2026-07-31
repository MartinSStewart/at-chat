module Evergreen.V341.VisibleMessages exposing (..)

import Evergreen.V341.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V341.Id.Id messageId
    , count : Int
    }
