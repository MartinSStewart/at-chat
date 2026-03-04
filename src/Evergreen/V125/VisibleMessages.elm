module Evergreen.V125.VisibleMessages exposing (..)

import Evergreen.V125.Id


type alias VisibleMessages messageId =
    { oldest : Evergreen.V125.Id.Id messageId
    , count : Int
    }
