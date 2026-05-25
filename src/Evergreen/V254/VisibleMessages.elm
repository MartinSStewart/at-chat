module Evergreen.V254.VisibleMessages exposing (..)

import Evergreen.V254.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V254.Id.Id messageId
    , count : Int
    }
