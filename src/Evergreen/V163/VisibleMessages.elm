module Evergreen.V163.VisibleMessages exposing (..)

import Evergreen.V163.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V163.Id.Id messageId
    , count : Int
    }
