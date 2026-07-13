module Evergreen.V318.VisibleMessages exposing (..)

import Evergreen.V318.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V318.Id.Id messageId
    , count : Int
    }
