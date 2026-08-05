module Evergreen.V345.VisibleMessages exposing (..)

import Evergreen.V345.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V345.Id.Id messageId
    , count : Int
    }
