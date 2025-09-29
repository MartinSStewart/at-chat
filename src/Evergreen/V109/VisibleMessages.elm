module Evergreen.V109.VisibleMessages exposing (..)

import Evergreen.V109.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V109.Id.Id messageId
    , count : Int
    }
