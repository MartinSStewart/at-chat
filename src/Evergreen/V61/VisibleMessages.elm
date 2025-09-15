module Evergreen.V61.VisibleMessages exposing (..)

import Evergreen.V61.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V61.Id.Id messageId
    , count : Int
    }
