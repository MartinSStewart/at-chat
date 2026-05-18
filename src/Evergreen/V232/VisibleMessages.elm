module Evergreen.V232.VisibleMessages exposing (..)

import Evergreen.V232.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V232.Id.Id messageId
    , count : Int
    }
