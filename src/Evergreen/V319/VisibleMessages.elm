module Evergreen.V319.VisibleMessages exposing (..)

import Evergreen.V319.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V319.Id.Id messageId
    , count : Int
    }
