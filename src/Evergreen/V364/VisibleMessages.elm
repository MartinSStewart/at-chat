module Evergreen.V364.VisibleMessages exposing (..)

import Evergreen.V364.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V364.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
