module Evergreen.V277.VisibleMessages exposing (..)

import Evergreen.V277.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V277.Id.Id messageId
    , count : Int
    }
