module Evergreen.V186.VisibleMessages exposing (..)

import Evergreen.V186.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V186.Id.Id messageId
    , count : Int
    }
