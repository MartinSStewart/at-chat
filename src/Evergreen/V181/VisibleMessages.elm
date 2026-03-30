module Evergreen.V181.VisibleMessages exposing (..)

import Evergreen.V181.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V181.Id.Id messageId
    , count : Int
    }
