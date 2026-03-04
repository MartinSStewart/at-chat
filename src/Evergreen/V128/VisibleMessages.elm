module Evergreen.V128.VisibleMessages exposing (..)

import Evergreen.V128.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V128.Id.Id messageId
    , count : Int
    }
