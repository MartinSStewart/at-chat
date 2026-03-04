module Evergreen.V130.VisibleMessages exposing (..)

import Evergreen.V130.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V130.Id.Id messageId
    , count : Int
    }
