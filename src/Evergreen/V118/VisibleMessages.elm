module Evergreen.V118.VisibleMessages exposing (..)

import Evergreen.V118.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V118.Id.Id messageId
    , count : Int
    }
