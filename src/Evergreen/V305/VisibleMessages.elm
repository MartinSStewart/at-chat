module Evergreen.V305.VisibleMessages exposing (..)

import Evergreen.V305.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V305.Id.Id messageId
    , count : Int
    }
