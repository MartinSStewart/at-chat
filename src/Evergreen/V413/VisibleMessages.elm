module Evergreen.V413.VisibleMessages exposing (..)

import Evergreen.V413.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V413.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }


type PageRequest messageId
    = PageBefore (Evergreen.V413.Id.Id messageId)
    | PageFrom (Evergreen.V413.Id.Id messageId)
