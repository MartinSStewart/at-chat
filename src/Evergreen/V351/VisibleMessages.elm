module Evergreen.V351.VisibleMessages exposing (..)

import Evergreen.V351.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V351.Id.Id messageId
    , count : Int
    }
