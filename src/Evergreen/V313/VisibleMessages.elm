module Evergreen.V313.VisibleMessages exposing (..)

import Evergreen.V313.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V313.Id.Id messageId
    , count : Int
    }
