module Evergreen.V332.VisibleMessages exposing (..)

import Evergreen.V332.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V332.Id.Id messageId
    , count : Int
    }
