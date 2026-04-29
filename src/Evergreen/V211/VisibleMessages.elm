module Evergreen.V211.VisibleMessages exposing (..)

import Evergreen.V211.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V211.Id.Id messageId
    , count : Int
    }
