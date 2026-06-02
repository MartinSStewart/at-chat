module Evergreen.V264.VisibleMessages exposing (..)

import Evergreen.V264.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V264.Id.Id messageId
    , count : Int
    }
