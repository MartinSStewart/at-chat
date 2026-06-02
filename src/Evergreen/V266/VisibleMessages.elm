module Evergreen.V266.VisibleMessages exposing (..)

import Evergreen.V266.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V266.Id.Id messageId
    , count : Int
    }
