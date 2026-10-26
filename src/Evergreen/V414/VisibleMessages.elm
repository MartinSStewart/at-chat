module Evergreen.V414.VisibleMessages exposing (..)

import Evergreen.V414.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V414.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V414.Id.Id messageId)
    | PageFrom (Evergreen.V414.Id.Id messageId)
