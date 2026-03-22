module Evergreen.V166.VisibleMessages exposing (..)

import Evergreen.V166.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V166.Id.Id messageId
    , count : Int
    }
