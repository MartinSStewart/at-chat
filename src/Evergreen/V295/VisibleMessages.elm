module Evergreen.V295.VisibleMessages exposing (..)

import Evergreen.V295.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V295.Id.Id messageId
    , count : Int
    }
