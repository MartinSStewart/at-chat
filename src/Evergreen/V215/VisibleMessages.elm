module Evergreen.V215.VisibleMessages exposing (..)

import Evergreen.V215.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V215.Id.Id messageId
    , count : Int
    }
