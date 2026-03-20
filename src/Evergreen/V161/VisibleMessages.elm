module Evergreen.V161.VisibleMessages exposing (..)

import Evergreen.V161.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V161.Id.Id messageId
    , count : Int
    }
