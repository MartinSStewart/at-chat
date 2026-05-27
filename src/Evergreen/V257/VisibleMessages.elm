module Evergreen.V257.VisibleMessages exposing (..)

import Evergreen.V257.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V257.Id.Id messageId
    , count : Int
    }
