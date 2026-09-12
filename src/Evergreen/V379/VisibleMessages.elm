module Evergreen.V379.VisibleMessages exposing (..)

import Evergreen.V379.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V379.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
