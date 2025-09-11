module Evergreen.V54.VisibleMessages exposing (..)

import Evergreen.V54.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V54.Id.Id messageId
    , count : Int
    }
