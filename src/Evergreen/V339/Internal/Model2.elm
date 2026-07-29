module Evergreen.V339.Internal.Model2 exposing (..)

import Evergreen.V339.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V339.Internal.Teleport.Trigger Evergreen.V339.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
