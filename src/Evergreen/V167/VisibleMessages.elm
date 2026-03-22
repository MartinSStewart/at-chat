module Evergreen.V167.VisibleMessages exposing (..)

import Evergreen.V167.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V167.Id.Id messageId
    , count : Int
    }
