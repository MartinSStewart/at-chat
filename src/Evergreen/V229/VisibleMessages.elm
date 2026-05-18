module Evergreen.V229.VisibleMessages exposing (..)

import Evergreen.V229.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V229.Id.Id messageId
    , count : Int
    }
