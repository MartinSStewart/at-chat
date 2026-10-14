module Evergreen.V407.VisibleMessages exposing (..)

import Evergreen.V407.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V407.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V407.Id.Id messageId)
    | PageFrom (Evergreen.V407.Id.Id messageId)
