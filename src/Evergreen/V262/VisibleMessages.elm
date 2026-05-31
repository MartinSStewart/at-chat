module Evergreen.V262.VisibleMessages exposing (..)

import Evergreen.V262.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V262.Id.Id messageId
    , count : Int
    }
