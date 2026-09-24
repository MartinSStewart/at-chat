module Evergreen.V385.VisibleMessages exposing (..)

import Evergreen.V385.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V385.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
