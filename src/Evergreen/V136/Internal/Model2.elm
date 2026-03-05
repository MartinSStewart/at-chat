module Evergreen.V136.Internal.Model2 exposing (..)

import Evergreen.V136.Internal.Teleport
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
    | Teleported Evergreen.V136.Internal.Teleport.Trigger Evergreen.V136.Internal.Teleport.Event
