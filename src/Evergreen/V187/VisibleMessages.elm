module Evergreen.V187.VisibleMessages exposing (..)

import Evergreen.V187.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V187.Id.Id messageId
    , count : Int
    }
