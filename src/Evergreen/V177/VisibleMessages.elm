module Evergreen.V177.VisibleMessages exposing (..)

import Evergreen.V177.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V177.Id.Id messageId
    , count : Int
    }
