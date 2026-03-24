module Evergreen.V169.VisibleMessages exposing (..)

import Evergreen.V169.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V169.Id.Id messageId
    , count : Int
    }
