module Evergreen.V255.VisibleMessages exposing (..)

import Evergreen.V255.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V255.Id.Id messageId
    , count : Int
    }
