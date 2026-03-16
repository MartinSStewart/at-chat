module Evergreen.V156.VisibleMessages exposing (..)

import Evergreen.V156.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V156.Id.Id messageId
    , count : Int
    }
