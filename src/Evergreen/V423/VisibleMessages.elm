module Evergreen.V423.VisibleMessages exposing (..)

import Evergreen.V423.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V423.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V423.Id.Id messageId)
    | PageFrom (Evergreen.V423.Id.Id messageId)
