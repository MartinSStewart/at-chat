module Evergreen.V296.VisibleMessages exposing (..)

import Evergreen.V296.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V296.Id.Id messageId
    , count : Int
    }
