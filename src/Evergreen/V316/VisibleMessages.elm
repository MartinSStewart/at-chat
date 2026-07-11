module Evergreen.V316.VisibleMessages exposing (..)

import Evergreen.V316.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V316.Id.Id messageId
    , count : Int
    }
