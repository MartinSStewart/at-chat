module Evergreen.V286.VisibleMessages exposing (..)

import Evergreen.V286.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V286.Id.Id messageId
    , count : Int
    }
