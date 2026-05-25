module Evergreen.V248.Internal.Model2 exposing (..)

import Evergreen.V248.Internal.Teleport
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
    | Teleported Evergreen.V248.Internal.Teleport.Trigger Evergreen.V248.Internal.Teleport.Event
