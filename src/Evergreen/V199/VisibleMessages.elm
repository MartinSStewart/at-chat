module Evergreen.V199.VisibleMessages exposing (..)

import Evergreen.V199.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V199.Id.Id messageId
    , count : Int
    }
