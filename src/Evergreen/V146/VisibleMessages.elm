module Evergreen.V146.VisibleMessages exposing (..)

import Evergreen.V146.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V146.Id.Id messageId
    , count : Int
    }
