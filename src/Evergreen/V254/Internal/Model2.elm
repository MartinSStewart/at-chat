module Evergreen.V254.Internal.Model2 exposing (..)

import Evergreen.V254.Internal.Teleport
import Set
import Time


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V254.Internal.Teleport.Trigger Evergreen.V254.Internal.Teleport.Event
