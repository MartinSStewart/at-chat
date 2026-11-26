module Evergreen.V426.VisibleMessages exposing (..)

import Evergreen.V426.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V426.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V426.Id.Id messageId)
    | PageFrom (Evergreen.V426.Id.Id messageId)
