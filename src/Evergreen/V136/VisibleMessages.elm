module Evergreen.V136.VisibleMessages exposing (..)

import Evergreen.V136.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V136.Id.Id messageId
    , count : Int
    }
