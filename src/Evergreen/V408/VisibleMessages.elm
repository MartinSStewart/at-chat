module Evergreen.V408.VisibleMessages exposing (..)

import Evergreen.V408.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V408.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V408.Id.Id messageId)
    | PageFrom (Evergreen.V408.Id.Id messageId)
