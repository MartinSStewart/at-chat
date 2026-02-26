module Evergreen.V121.VisibleMessages exposing (..)

import Evergreen.V121.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V121.Id.Id messageId
    , count : Int
    }
