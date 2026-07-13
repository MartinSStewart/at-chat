module Evergreen.V317.VisibleMessages exposing (..)

import Evergreen.V317.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V317.Id.Id messageId
    , count : Int
    }
