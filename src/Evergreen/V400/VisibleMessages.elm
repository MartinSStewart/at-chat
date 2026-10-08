module Evergreen.V400.VisibleMessages exposing (..)

import Evergreen.V400.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V400.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
