module Evergreen.V214.VisibleMessages exposing (..)

import Evergreen.V214.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V214.Id.Id messageId
    , count : Int
    }
