module Evergreen.V122.VisibleMessages exposing (..)

import Evergreen.V122.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V122.Id.Id messageId
    , count : Int
    }
