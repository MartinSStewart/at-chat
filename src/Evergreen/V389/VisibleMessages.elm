module Evergreen.V389.VisibleMessages exposing (..)

import Evergreen.V389.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V389.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
