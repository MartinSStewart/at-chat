module Evergreen.V160.VisibleMessages exposing (..)

import Evergreen.V160.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V160.Id.Id messageId
    , count : Int
    }
