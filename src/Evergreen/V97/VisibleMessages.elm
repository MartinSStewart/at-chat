module Evergreen.V97.VisibleMessages exposing (..)

import Evergreen.V97.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V97.Id.Id messageId
    , count : Int
    }
