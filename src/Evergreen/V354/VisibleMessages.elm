module Evergreen.V354.VisibleMessages exposing (..)

import Evergreen.V354.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V354.Id.Id messageId
    , count : Int
    }
