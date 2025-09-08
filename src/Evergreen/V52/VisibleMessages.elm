module Evergreen.V52.VisibleMessages exposing (..)

import Evergreen.V52.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V52.Id.Id messageId
    , count : Int
    }
