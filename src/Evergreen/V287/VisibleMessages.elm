module Evergreen.V287.VisibleMessages exposing (..)

import Evergreen.V287.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V287.Id.Id messageId
    , count : Int
    }
