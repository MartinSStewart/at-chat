module Evergreen.V171.VisibleMessages exposing (..)

import Evergreen.V171.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V171.Id.Id messageId
    , count : Int
    }
