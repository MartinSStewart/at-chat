module Evergreen.V76.VisibleMessages exposing (..)

import Evergreen.V76.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V76.Id.Id messageId
    , count : Int
    }
