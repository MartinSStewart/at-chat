module Evergreen.V405.VisibleMessages exposing (..)

import Evergreen.V405.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V405.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V405.Id.Id messageId)
    | PageFrom (Evergreen.V405.Id.Id messageId)
