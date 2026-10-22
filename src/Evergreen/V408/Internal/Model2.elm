module Evergreen.V408.Internal.Model2 exposing (..)

import Evergreen.V408.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V408.Internal.Teleport.Trigger Evergreen.V408.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
