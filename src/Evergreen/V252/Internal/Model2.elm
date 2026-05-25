module Evergreen.V252.Internal.Model2 exposing (..)

import Evergreen.V252.Internal.Teleport
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
    | Teleported Evergreen.V252.Internal.Teleport.Trigger Evergreen.V252.Internal.Teleport.Event
