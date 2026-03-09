module Evergreen.V148.VisibleMessages exposing (..)

import Evergreen.V148.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V148.Id.Id messageId
    , count : Int
    }
