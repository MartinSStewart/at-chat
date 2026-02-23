module Evergreen.V120.Internal.Model2 exposing (..)

import Evergreen.V120.Internal.Teleport
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
    | Teleported Evergreen.V120.Internal.Teleport.Trigger Evergreen.V120.Internal.Teleport.Event
