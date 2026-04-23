module Evergreen.V207.VisibleMessages exposing (..)

import Evergreen.V207.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V207.Id.Id messageId
    , count : Int
    }
