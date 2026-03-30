module Evergreen.V179.VisibleMessages exposing (..)

import Evergreen.V179.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V179.Id.Id messageId
    , count : Int
    }
