module Evergreen.V196.VisibleMessages exposing (..)

import Evergreen.V196.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V196.Id.Id messageId
    , count : Int
    }
