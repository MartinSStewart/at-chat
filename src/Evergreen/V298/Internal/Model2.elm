module Evergreen.V298.Internal.Model2 exposing (..)

import Evergreen.V298.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V298.Internal.Teleport.Trigger Evergreen.V298.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
