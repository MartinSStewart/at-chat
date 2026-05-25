module Evergreen.V252.VisibleMessages exposing (..)

import Evergreen.V252.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V252.Id.Id messageId
    , count : Int
    }
