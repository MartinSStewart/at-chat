module Evergreen.V384.Internal.Model2 exposing (..)

import Evergreen.V384.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V384.Internal.Teleport.Trigger Evergreen.V384.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
