module Evergreen.V175.Internal.Model2 exposing (..)

import Evergreen.V175.Internal.Teleport
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
    | Teleported Evergreen.V175.Internal.Teleport.Trigger Evergreen.V175.Internal.Teleport.Event
