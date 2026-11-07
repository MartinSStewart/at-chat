module Evergreen.V421.VisibleMessages exposing (..)

import Evergreen.V421.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V421.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V421.Id.Id messageId)
    | PageFrom (Evergreen.V421.Id.Id messageId)
