module Evergreen.V218.VisibleMessages exposing (..)

import Evergreen.V218.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V218.Id.Id messageId
    , count : Int
    }
