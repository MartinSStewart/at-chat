module Evergreen.V288.VisibleMessages exposing (..)

import Evergreen.V288.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V288.Id.Id messageId
    , count : Int
    }
