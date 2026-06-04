module Evergreen.V271.VisibleMessages exposing (..)

import Evergreen.V271.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V271.Id.Id messageId
    , count : Int
    }
