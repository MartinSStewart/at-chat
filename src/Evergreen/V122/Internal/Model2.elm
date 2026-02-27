module Evergreen.V122.Internal.Model2 exposing (..)

import Evergreen.V122.Internal.Teleport
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
    | Teleported Evergreen.V122.Internal.Teleport.Trigger Evergreen.V122.Internal.Teleport.Event
