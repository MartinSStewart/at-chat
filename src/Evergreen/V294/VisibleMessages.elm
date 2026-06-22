module Evergreen.V294.VisibleMessages exposing (..)

import Evergreen.V294.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V294.Id.Id messageId
    , count : Int
    }
