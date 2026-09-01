module Evergreen.V366.VisibleMessages exposing (..)

import Evergreen.V366.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V366.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
