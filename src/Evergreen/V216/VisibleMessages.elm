module Evergreen.V216.VisibleMessages exposing (..)

import Evergreen.V216.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V216.Id.Id messageId
    , count : Int
    }
