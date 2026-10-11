module Evergreen.V403.Internal.Model2 exposing (..)

import Evergreen.V403.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V403.Internal.Teleport.Trigger Evergreen.V403.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
