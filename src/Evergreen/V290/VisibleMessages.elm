module Evergreen.V290.VisibleMessages exposing (..)

import Evergreen.V290.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V290.Id.Id messageId
    , count : Int
    }
