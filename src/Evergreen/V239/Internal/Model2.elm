module Evergreen.V239.Internal.Model2 exposing (..)

import Evergreen.V239.Internal.Teleport
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
    | Teleported Evergreen.V239.Internal.Teleport.Trigger Evergreen.V239.Internal.Teleport.Event
