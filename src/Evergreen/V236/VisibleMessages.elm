module Evergreen.V236.VisibleMessages exposing (..)

import Evergreen.V236.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V236.Id.Id messageId
    , count : Int
    }
