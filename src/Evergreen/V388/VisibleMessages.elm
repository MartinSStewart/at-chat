module Evergreen.V388.VisibleMessages exposing (..)

import Evergreen.V388.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V388.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
