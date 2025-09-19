module Evergreen.V90.VisibleMessages exposing (..)

import Evergreen.V90.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V90.Id.Id messageId
    , count : Int
    }
