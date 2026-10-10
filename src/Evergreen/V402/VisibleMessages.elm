module Evergreen.V402.VisibleMessages exposing (..)

import Evergreen.V402.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V402.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
