module Evergreen.V176.VisibleMessages exposing (..)

import Evergreen.V176.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V176.Id.Id messageId
    , count : Int
    }
