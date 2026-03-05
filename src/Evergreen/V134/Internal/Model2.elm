module Evergreen.V134.Internal.Model2 exposing (..)

import Evergreen.V134.Internal.Teleport
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
    | Teleported Evergreen.V134.Internal.Teleport.Trigger Evergreen.V134.Internal.Teleport.Event
