module Evergreen.V312.VisibleMessages exposing (..)

import Evergreen.V312.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V312.Id.Id messageId
    , count : Int
    }
