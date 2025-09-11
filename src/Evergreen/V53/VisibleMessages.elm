module Evergreen.V53.VisibleMessages exposing (..)

import Evergreen.V53.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V53.Id.Id messageId
    , count : Int
    }
