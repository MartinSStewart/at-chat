module Evergreen.V347.VisibleMessages exposing (..)

import Evergreen.V347.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V347.Id.Id messageId
    , count : Int
    }
