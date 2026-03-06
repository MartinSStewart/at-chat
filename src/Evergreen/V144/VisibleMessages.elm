module Evergreen.V144.VisibleMessages exposing (..)

import Evergreen.V144.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V144.Id.Id messageId
    , count : Int
    }
