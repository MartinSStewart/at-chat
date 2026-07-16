module Evergreen.V326.VisibleMessages exposing (..)

import Evergreen.V326.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V326.Id.Id messageId
    , count : Int
    }
