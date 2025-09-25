module Evergreen.V104.Internal.Model2 exposing (..)

import Evergreen.V104.Internal.Teleport
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
    | Teleported Evergreen.V104.Internal.Teleport.Trigger Evergreen.V104.Internal.Teleport.Event
