module Evergreen.V240.VisibleMessages exposing (..)

import Evergreen.V240.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V240.Id.Id messageId
    , count : Int
    }
