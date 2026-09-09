module Evergreen.V375.VisibleMessages exposing (..)

import Evergreen.V375.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V375.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
