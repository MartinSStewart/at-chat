module Evergreen.V238.VisibleMessages exposing (..)

import Evergreen.V238.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V238.Id.Id messageId
    , count : Int
    }
