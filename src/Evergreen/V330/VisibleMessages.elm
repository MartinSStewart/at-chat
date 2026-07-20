module Evergreen.V330.VisibleMessages exposing (..)

import Evergreen.V330.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V330.Id.Id messageId
    , count : Int
    }
