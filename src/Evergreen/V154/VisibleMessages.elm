module Evergreen.V154.VisibleMessages exposing (..)

import Evergreen.V154.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V154.Id.Id messageId
    , count : Int
    }
