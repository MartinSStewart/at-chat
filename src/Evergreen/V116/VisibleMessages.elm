module Evergreen.V116.VisibleMessages exposing (..)

import Evergreen.V116.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V116.Id.Id messageId
    , count : Int
    }
