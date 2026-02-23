module Evergreen.V119.VisibleMessages exposing (..)

import Evergreen.V119.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V119.Id.Id messageId
    , count : Int
    }
