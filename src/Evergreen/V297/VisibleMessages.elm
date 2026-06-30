module Evergreen.V297.VisibleMessages exposing (..)

import Evergreen.V297.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V297.Id.Id messageId
    , count : Int
    }
