module Evergreen.V94.VisibleMessages exposing (..)

import Evergreen.V94.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V94.Id.Id messageId
    , count : Int
    }
