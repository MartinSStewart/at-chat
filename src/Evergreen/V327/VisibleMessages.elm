module Evergreen.V327.VisibleMessages exposing (..)

import Evergreen.V327.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V327.Id.Id messageId
    , count : Int
    }
