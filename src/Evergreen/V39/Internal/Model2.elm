module Evergreen.V39.Internal.Model2 exposing (..)

import Evergreen.V39.Internal.Teleport
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
    | Teleported Evergreen.V39.Internal.Teleport.Trigger Evergreen.V39.Internal.Teleport.Event
