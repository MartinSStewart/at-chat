module Evergreen.V261.VisibleMessages exposing (..)

import Evergreen.V261.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V261.Id.Id messageId
    , count : Int
    }
