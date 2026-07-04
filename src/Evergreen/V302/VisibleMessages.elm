module Evergreen.V302.VisibleMessages exposing (..)

import Evergreen.V302.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V302.Id.Id messageId
    , count : Int
    }
