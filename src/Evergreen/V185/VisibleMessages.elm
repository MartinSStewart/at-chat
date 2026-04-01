module Evergreen.V185.VisibleMessages exposing (..)

import Evergreen.V185.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V185.Id.Id messageId
    , count : Int
    }
