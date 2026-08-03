module Evergreen.V344.VisibleMessages exposing (..)

import Evergreen.V344.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V344.Id.Id messageId
    , count : Int
    }
