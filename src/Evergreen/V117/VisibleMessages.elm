module Evergreen.V117.VisibleMessages exposing (..)

import Evergreen.V117.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V117.Id.Id messageId
    , count : Int
    }
