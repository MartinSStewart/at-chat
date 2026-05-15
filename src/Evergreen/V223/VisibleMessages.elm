module Evergreen.V223.VisibleMessages exposing (..)

import Evergreen.V223.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V223.Id.Id messageId
    , count : Int
    }
