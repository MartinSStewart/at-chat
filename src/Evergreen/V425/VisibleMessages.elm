module Evergreen.V425.VisibleMessages exposing (..)

import Evergreen.V425.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V425.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V425.Id.Id messageId)
    | PageFrom (Evergreen.V425.Id.Id messageId)
