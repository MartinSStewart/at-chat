module Evergreen.V358.VisibleMessages exposing (..)

import Evergreen.V358.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V358.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
