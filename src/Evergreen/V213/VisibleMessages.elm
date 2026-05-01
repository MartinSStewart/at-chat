module Evergreen.V213.VisibleMessages exposing (..)

import Evergreen.V213.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V213.Id.Id messageId
    , count : Int
    }
