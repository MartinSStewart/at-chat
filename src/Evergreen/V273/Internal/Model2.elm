module Evergreen.V273.Internal.Model2 exposing (..)

import Evergreen.V273.Internal.Teleport
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
    | Teleported Evergreen.V273.Internal.Teleport.Trigger Evergreen.V273.Internal.Teleport.Event
