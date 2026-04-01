module Evergreen.V183.VisibleMessages exposing (..)

import Evergreen.V183.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V183.Id.Id messageId
    , count : Int
    }
