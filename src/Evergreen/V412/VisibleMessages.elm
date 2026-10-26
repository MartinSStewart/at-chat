module Evergreen.V412.VisibleMessages exposing (..)

import Evergreen.V412.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V412.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V412.Id.Id messageId)
    | PageFrom (Evergreen.V412.Id.Id messageId)
