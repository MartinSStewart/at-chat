module Evergreen.V402.Internal.Model2 exposing (..)

import Evergreen.V402.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V402.Internal.Teleport.Trigger Evergreen.V402.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
