module Evergreen.V372.VisibleMessages exposing (..)

import Evergreen.V372.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V372.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
