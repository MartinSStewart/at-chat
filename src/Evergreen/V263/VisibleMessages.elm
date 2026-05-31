module Evergreen.V263.VisibleMessages exposing (..)

import Evergreen.V263.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V263.Id.Id messageId
    , count : Int
    }
