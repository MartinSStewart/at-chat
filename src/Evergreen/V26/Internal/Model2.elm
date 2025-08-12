module Evergreen.V26.Internal.Model2 exposing (..)

import Evergreen.V26.Internal.Teleport
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
    | Teleported Evergreen.V26.Internal.Teleport.Trigger Evergreen.V26.Internal.Teleport.Event
