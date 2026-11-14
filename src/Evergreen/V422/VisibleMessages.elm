module Evergreen.V422.VisibleMessages exposing (..)

import Evergreen.V422.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V422.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V422.Id.Id messageId)
    | PageFrom (Evergreen.V422.Id.Id messageId)
