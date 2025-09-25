module Evergreen.V108.VisibleMessages exposing (..)

import Evergreen.V108.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V108.Id.Id messageId
    , count : Int
    }
