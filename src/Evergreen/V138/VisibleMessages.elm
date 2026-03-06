module Evergreen.V138.VisibleMessages exposing (..)

import Evergreen.V138.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V138.Id.Id messageId
    , count : Int
    }
