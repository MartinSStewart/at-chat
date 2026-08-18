module Evergreen.V357.VisibleMessages exposing (..)

import Evergreen.V357.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V357.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
