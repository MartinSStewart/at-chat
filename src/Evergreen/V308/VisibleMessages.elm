module Evergreen.V308.VisibleMessages exposing (..)

import Evergreen.V308.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V308.Id.Id messageId
    , count : Int
    }
