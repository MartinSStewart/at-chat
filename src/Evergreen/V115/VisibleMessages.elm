module Evergreen.V115.VisibleMessages exposing (..)

import Evergreen.V115.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V115.Id.Id messageId
    , count : Int
    }
