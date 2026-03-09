module Evergreen.V147.VisibleMessages exposing (..)

import Evergreen.V147.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V147.Id.Id messageId
    , count : Int
    }
