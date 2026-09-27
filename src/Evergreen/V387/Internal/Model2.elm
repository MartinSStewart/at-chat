module Evergreen.V387.Internal.Model2 exposing (..)

import Evergreen.V387.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V387.Internal.Teleport.Trigger Evergreen.V387.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
