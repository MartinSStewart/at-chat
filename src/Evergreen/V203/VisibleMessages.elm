module Evergreen.V203.VisibleMessages exposing (..)

import Evergreen.V203.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V203.Id.Id messageId
    , count : Int
    }
