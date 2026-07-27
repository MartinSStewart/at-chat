module Evergreen.V335.VisibleMessages exposing (..)

import Evergreen.V335.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V335.Id.Id messageId
    , count : Int
    }
