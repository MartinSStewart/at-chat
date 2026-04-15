module Evergreen.V201.VisibleMessages exposing (..)

import Evergreen.V201.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V201.Id.Id messageId
    , count : Int
    }
