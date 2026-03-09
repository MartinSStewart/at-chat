module Evergreen.V149.VisibleMessages exposing (..)

import Evergreen.V149.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V149.Id.Id messageId
    , count : Int
    }
