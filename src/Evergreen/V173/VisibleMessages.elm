module Evergreen.V173.VisibleMessages exposing (..)

import Evergreen.V173.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V173.Id.Id messageId
    , count : Int
    }
