module Evergreen.V353.VisibleMessages exposing (..)

import Evergreen.V353.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V353.Id.Id messageId
    , count : Int
    }
