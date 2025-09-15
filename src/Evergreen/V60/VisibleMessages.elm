module Evergreen.V60.VisibleMessages exposing (..)

import Evergreen.V60.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V60.Id.Id messageId
    , count : Int
    }
