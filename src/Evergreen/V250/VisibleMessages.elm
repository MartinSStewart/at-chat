module Evergreen.V250.VisibleMessages exposing (..)

import Evergreen.V250.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V250.Id.Id messageId
    , count : Int
    }
