module Evergreen.V209.VisibleMessages exposing (..)

import Evergreen.V209.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V209.Id.Id messageId
    , count : Int
    }
