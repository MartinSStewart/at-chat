module Evergreen.V403.VisibleMessages exposing (..)

import Evergreen.V403.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V403.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V403.Id.Id messageId)
    | PageFrom (Evergreen.V403.Id.Id messageId)
