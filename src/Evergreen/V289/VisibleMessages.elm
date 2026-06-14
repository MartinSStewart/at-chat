module Evergreen.V289.VisibleMessages exposing (..)

import Evergreen.V289.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V289.Id.Id messageId
    , count : Int
    }
