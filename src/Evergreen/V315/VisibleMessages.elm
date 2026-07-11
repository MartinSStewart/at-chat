module Evergreen.V315.VisibleMessages exposing (..)

import Evergreen.V315.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V315.Id.Id messageId
    , count : Int
    }
