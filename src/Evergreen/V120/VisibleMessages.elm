module Evergreen.V120.VisibleMessages exposing (..)

import Evergreen.V120.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V120.Id.Id messageId
    , count : Int
    }
