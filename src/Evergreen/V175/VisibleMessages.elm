module Evergreen.V175.VisibleMessages exposing (..)

import Evergreen.V175.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V175.Id.Id messageId
    , count : Int
    }
