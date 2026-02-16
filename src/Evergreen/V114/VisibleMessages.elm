module Evergreen.V114.VisibleMessages exposing (..)

import Evergreen.V114.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V114.Id.Id messageId
    , count : Int
    }
