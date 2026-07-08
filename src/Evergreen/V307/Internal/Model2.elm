module Evergreen.V307.Internal.Model2 exposing (..)

import Evergreen.V307.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V307.Internal.Teleport.Trigger Evergreen.V307.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
