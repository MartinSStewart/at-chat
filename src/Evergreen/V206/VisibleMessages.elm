module Evergreen.V206.VisibleMessages exposing (..)

import Evergreen.V206.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V206.Id.Id messageId
    , count : Int
    }
