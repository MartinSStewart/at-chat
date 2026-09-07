module Evergreen.V370.VisibleMessages exposing (..)

import Evergreen.V370.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V370.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
