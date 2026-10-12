module Evergreen.V404.VisibleMessages exposing (..)

import Evergreen.V404.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V404.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V404.Id.Id messageId)
    | PageFrom (Evergreen.V404.Id.Id messageId)
