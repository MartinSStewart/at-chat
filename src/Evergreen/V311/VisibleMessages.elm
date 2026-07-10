module Evergreen.V311.VisibleMessages exposing (..)

import Evergreen.V311.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V311.Id.Id messageId
    , count : Int
    }
