module Evergreen.V112.Internal.Model2 exposing (..)

import Evergreen.V112.Internal.Teleport
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
    | Teleported Evergreen.V112.Internal.Teleport.Trigger Evergreen.V112.Internal.Teleport.Event
