module Evergreen.V385.Internal.Model2 exposing (..)

import Evergreen.V385.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V385.Internal.Teleport.Trigger Evergreen.V385.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
