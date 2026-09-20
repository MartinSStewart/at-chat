module Evergreen.V384.VisibleMessages exposing (..)

import Evergreen.V384.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V384.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
