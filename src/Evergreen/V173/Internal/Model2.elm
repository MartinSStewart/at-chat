module Evergreen.V173.Internal.Model2 exposing (..)

import Evergreen.V173.Internal.Teleport
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
    | Teleported Evergreen.V173.Internal.Teleport.Trigger Evergreen.V173.Internal.Teleport.Event
