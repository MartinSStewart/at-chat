module Evergreen.V419.VisibleMessages exposing (..)

import Evergreen.V419.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V419.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V419.Id.Id messageId)
    | PageFrom (Evergreen.V419.Id.Id messageId)
