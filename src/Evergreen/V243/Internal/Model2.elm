module Evergreen.V243.Internal.Model2 exposing (..)

import Evergreen.V243.Internal.Teleport
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
    | Teleported Evergreen.V243.Internal.Teleport.Trigger Evergreen.V243.Internal.Teleport.Event
