module Evergreen.V360.VisibleMessages exposing (..)

import Evergreen.V360.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V360.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
