module Evergreen.V309.VisibleMessages exposing (..)

import Evergreen.V309.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V309.Id.Id messageId
    , count : Int
    }
