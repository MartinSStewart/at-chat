module Evergreen.V365.VisibleMessages exposing (..)

import Evergreen.V365.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V365.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
