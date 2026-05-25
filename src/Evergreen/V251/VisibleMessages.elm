module Evergreen.V251.VisibleMessages exposing (..)

import Evergreen.V251.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V251.Id.Id messageId
    , count : Int
    }
