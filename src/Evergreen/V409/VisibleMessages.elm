module Evergreen.V409.VisibleMessages exposing (..)

import Evergreen.V409.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V409.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V409.Id.Id messageId)
    | PageFrom (Evergreen.V409.Id.Id messageId)
