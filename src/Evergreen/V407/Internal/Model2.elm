module Evergreen.V407.Internal.Model2 exposing (..)

import Evergreen.V407.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V407.Internal.Teleport.Trigger Evergreen.V407.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
