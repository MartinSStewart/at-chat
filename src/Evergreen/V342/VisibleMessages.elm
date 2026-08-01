module Evergreen.V342.VisibleMessages exposing (..)

import Evergreen.V342.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V342.Id.Id messageId
    , count : Int
    }
