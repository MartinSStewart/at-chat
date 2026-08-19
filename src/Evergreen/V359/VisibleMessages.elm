module Evergreen.V359.VisibleMessages exposing (..)

import Evergreen.V359.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V359.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
