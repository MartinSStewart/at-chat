module Evergreen.V182.Internal.Model2 exposing (..)

import Evergreen.V182.Internal.Teleport
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
    | Teleported Evergreen.V182.Internal.Teleport.Trigger Evergreen.V182.Internal.Teleport.Event
