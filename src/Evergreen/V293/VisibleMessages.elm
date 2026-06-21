module Evergreen.V293.VisibleMessages exposing (..)

import Evergreen.V293.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V293.Id.Id messageId
    , count : Int
    }
