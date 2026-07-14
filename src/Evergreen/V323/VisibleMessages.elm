module Evergreen.V323.VisibleMessages exposing (..)

import Evergreen.V323.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V323.Id.Id messageId
    , count : Int
    }
