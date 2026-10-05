module Evergreen.V398.VisibleMessages exposing (..)

import Evergreen.V398.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V398.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
