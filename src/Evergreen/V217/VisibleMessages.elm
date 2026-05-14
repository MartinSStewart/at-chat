module Evergreen.V217.VisibleMessages exposing (..)

import Evergreen.V217.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V217.Id.Id messageId
    , count : Int
    }
