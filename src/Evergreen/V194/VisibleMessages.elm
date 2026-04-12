module Evergreen.V194.VisibleMessages exposing (..)

import Evergreen.V194.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V194.Id.Id messageId
    , count : Int
    }
