module Evergreen.V210.VisibleMessages exposing (..)

import Evergreen.V210.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V210.Id.Id messageId
    , count : Int
    }
