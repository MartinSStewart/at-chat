module Evergreen.V190.VisibleMessages exposing (..)

import Evergreen.V190.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V190.Id.Id messageId
    , count : Int
    }
