module Evergreen.V298.VisibleMessages exposing (..)

import Evergreen.V298.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V298.Id.Id messageId
    , count : Int
    }
