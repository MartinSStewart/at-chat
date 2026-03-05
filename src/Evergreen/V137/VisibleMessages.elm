module Evergreen.V137.VisibleMessages exposing (..)

import Evergreen.V137.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V137.Id.Id messageId
    , count : Int
    }
