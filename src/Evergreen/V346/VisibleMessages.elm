module Evergreen.V346.VisibleMessages exposing (..)

import Evergreen.V346.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V346.Id.Id messageId
    , count : Int
    }
