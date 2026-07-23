module Evergreen.V334.VisibleMessages exposing (..)

import Evergreen.V334.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V334.Id.Id messageId
    , count : Int
    }
