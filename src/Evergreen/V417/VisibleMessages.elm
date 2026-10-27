module Evergreen.V417.VisibleMessages exposing (..)

import Evergreen.V417.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V417.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V417.Id.Id messageId)
    | PageFrom (Evergreen.V417.Id.Id messageId)
