module Evergreen.V92.VisibleMessages exposing (..)

import Evergreen.V92.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V92.Id.Id messageId
    , count : Int
    }
