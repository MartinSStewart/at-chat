module Evergreen.V302.Internal.Model2 exposing (..)

import Evergreen.V302.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V302.Internal.Teleport.Trigger Evergreen.V302.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
