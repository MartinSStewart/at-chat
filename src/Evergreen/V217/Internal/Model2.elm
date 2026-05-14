module Evergreen.V217.Internal.Model2 exposing (..)

import Evergreen.V217.Internal.Teleport
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
    | Teleported Evergreen.V217.Internal.Teleport.Trigger Evergreen.V217.Internal.Teleport.Event
