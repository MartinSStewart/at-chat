module Evergreen.V124.VisibleMessages exposing (..)

import Evergreen.V124.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V124.Id.Id messageId
    , count : Int
    }
