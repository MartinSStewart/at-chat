module Evergreen.V269.VisibleMessages exposing (..)

import Evergreen.V269.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V269.Id.Id messageId
    , count : Int
    }
