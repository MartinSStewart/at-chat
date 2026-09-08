module Evergreen.V373.VisibleMessages exposing (..)

import Evergreen.V373.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V373.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
