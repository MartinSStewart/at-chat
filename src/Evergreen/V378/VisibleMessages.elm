module Evergreen.V378.VisibleMessages exposing (..)

import Evergreen.V378.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V378.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
