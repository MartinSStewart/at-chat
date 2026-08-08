module Evergreen.V348.VisibleMessages exposing (..)

import Evergreen.V348.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V348.Id.Id messageId
    , count : Int
    }
