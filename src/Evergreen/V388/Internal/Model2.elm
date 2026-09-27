module Evergreen.V388.Internal.Model2 exposing (..)

import Evergreen.V388.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V388.Internal.Teleport.Trigger Evergreen.V388.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
