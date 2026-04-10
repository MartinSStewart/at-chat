module Evergreen.V193.VisibleMessages exposing (..)

import Evergreen.V193.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V193.Id.Id messageId
    , count : Int
    }
