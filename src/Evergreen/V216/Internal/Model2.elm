module Evergreen.V216.Internal.Model2 exposing (..)

import Evergreen.V216.Internal.Teleport
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
    | Teleported Evergreen.V216.Internal.Teleport.Trigger Evergreen.V216.Internal.Teleport.Event
