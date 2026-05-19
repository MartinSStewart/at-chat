module Evergreen.V239.VisibleMessages exposing (..)

import Evergreen.V239.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V239.Id.Id messageId
    , count : Int
    }
