module Evergreen.V307.VisibleMessages exposing (..)

import Evergreen.V307.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V307.Id.Id messageId
    , count : Int
    }
