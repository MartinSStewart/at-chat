module Evergreen.V349.VisibleMessages exposing (..)

import Evergreen.V349.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V349.Id.Id messageId
    , count : Int
    }
