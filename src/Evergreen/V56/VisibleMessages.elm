module Evergreen.V56.VisibleMessages exposing (..)

import Evergreen.V56.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V56.Id.Id messageId
    , count : Int
    }
