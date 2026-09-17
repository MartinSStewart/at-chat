module Evergreen.V383.VisibleMessages exposing (..)

import Evergreen.V383.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V383.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
