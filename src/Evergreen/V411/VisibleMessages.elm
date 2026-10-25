module Evergreen.V411.VisibleMessages exposing (..)

import Evergreen.V411.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V411.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V411.Id.Id messageId)
    | PageFrom (Evergreen.V411.Id.Id messageId)
