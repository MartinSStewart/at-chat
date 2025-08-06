module Evergreen.V17.Internal.Model2 exposing (..)

import Evergreen.V17.Internal.Teleport
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
    | Teleported Evergreen.V17.Internal.Teleport.Trigger Evergreen.V17.Internal.Teleport.Event
