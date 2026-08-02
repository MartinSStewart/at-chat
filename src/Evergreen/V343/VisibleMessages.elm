module Evergreen.V343.VisibleMessages exposing (..)

import Evergreen.V343.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V343.Id.Id messageId
    , count : Int
    }
