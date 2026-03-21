module Evergreen.V163.Internal.Model2 exposing (..)

import Evergreen.V163.Internal.Teleport
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
    | Teleported Evergreen.V163.Internal.Teleport.Trigger Evergreen.V163.Internal.Teleport.Event
