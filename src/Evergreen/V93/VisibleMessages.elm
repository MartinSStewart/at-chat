module Evergreen.V93.VisibleMessages exposing (..)

import Evergreen.V93.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V93.Id.Id messageId
    , count : Int
    }
