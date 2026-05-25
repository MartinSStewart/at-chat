module Evergreen.V253.VisibleMessages exposing (..)

import Evergreen.V253.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V253.Id.Id messageId
    , count : Int
    }
