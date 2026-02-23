module Evergreen.V118.Internal.Model2 exposing (..)

import Evergreen.V118.Internal.Teleport
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
    | Teleported Evergreen.V118.Internal.Teleport.Trigger Evergreen.V118.Internal.Teleport.Event
