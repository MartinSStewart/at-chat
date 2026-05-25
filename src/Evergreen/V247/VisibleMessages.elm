module Evergreen.V247.VisibleMessages exposing (..)

import Evergreen.V247.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V247.Id.Id messageId
    , count : Int
    }
