module Evergreen.V101.VisibleMessages exposing (..)

import Evergreen.V101.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V101.Id.Id messageId
    , count : Int
    }
