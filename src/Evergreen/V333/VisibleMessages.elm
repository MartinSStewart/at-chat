module Evergreen.V333.VisibleMessages exposing (..)

import Evergreen.V333.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V333.Id.Id messageId
    , count : Int
    }
