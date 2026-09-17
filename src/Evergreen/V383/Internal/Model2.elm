module Evergreen.V383.Internal.Model2 exposing (..)

import Evergreen.V383.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V383.Internal.Teleport.Trigger Evergreen.V383.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
