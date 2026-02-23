module Evergreen.V119.Internal.Model2 exposing (..)

import Evergreen.V119.Internal.Teleport
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
    | Teleported Evergreen.V119.Internal.Teleport.Trigger Evergreen.V119.Internal.Teleport.Event
