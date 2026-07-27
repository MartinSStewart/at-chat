module Evergreen.V336.VisibleMessages exposing (..)

import Evergreen.V336.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V336.Id.Id messageId
    , count : Int
    }
