module Evergreen.V104.VisibleMessages exposing (..)

import Evergreen.V104.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V104.Id.Id messageId
    , count : Int
    }
