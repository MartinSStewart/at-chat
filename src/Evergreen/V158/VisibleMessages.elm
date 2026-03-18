module Evergreen.V158.VisibleMessages exposing (..)

import Evergreen.V158.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V158.Id.Id messageId
    , count : Int
    }
