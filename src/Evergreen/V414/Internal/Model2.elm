module Evergreen.V414.Internal.Model2 exposing (..)

import Evergreen.V414.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V414.Internal.Teleport.Trigger Evergreen.V414.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
