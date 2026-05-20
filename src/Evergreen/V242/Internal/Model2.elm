module Evergreen.V242.Internal.Model2 exposing (..)

import Evergreen.V242.Internal.Teleport
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
    | Teleported Evergreen.V242.Internal.Teleport.Trigger Evergreen.V242.Internal.Teleport.Event
