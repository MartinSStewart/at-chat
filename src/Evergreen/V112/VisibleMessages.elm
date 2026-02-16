module Evergreen.V112.VisibleMessages exposing (..)

import Evergreen.V112.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V112.Id.Id messageId
    , count : Int
    }
