module Evergreen.V184.VisibleMessages exposing (..)

import Evergreen.V184.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V184.Id.Id messageId
    , count : Int
    }
