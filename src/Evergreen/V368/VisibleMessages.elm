module Evergreen.V368.VisibleMessages exposing (..)

import Evergreen.V368.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V368.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
