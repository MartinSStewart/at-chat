module Evergreen.V406.VisibleMessages exposing (..)

import Evergreen.V406.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V406.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V406.Id.Id messageId)
    | PageFrom (Evergreen.V406.Id.Id messageId)
