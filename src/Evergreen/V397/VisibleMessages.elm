module Evergreen.V397.VisibleMessages exposing (..)

import Evergreen.V397.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V397.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
