module Evergreen.V338.VisibleMessages exposing (..)

import Evergreen.V338.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V338.Id.Id messageId
    , count : Int
    }
