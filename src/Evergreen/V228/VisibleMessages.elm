module Evergreen.V228.VisibleMessages exposing (..)

import Evergreen.V228.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V228.Id.Id messageId
    , count : Int
    }
