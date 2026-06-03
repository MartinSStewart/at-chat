module Evergreen.V270.VisibleMessages exposing (..)

import Evergreen.V270.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V270.Id.Id messageId
    , count : Int
    }
