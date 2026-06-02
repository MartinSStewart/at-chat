module Evergreen.V267.VisibleMessages exposing (..)

import Evergreen.V267.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V267.Id.Id messageId
    , count : Int
    }
