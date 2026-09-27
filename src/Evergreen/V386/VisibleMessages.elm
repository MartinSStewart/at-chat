module Evergreen.V386.VisibleMessages exposing (..)

import Evergreen.V386.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V386.Id.Id messageId
    , count : Int
    , loadingMessages : Bool
    }
