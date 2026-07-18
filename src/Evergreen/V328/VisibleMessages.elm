module Evergreen.V328.VisibleMessages exposing (..)

import Evergreen.V328.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V328.Id.Id messageId
    , count : Int
    }
