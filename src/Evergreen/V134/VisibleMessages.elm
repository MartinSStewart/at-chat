module Evergreen.V134.VisibleMessages exposing (..)

import Evergreen.V134.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V134.Id.Id messageId
    , count : Int
    }
