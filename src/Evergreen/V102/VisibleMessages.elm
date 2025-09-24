module Evergreen.V102.VisibleMessages exposing (..)

import Evergreen.V102.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V102.Id.Id messageId
    , count : Int
    }
