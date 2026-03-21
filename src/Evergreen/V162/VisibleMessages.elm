module Evergreen.V162.VisibleMessages exposing (..)

import Evergreen.V162.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V162.Id.Id messageId
    , count : Int
    }
