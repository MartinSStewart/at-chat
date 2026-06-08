module Evergreen.V279.VisibleMessages exposing (..)

import Evergreen.V279.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V279.Id.Id messageId
    , count : Int
    }
