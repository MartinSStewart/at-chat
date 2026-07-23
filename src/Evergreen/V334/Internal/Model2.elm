module Evergreen.V334.Internal.Model2 exposing (..)

import Evergreen.V334.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V334.Internal.Teleport.Trigger Evergreen.V334.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
