module Evergreen.V342.Internal.Model2 exposing (..)

import Evergreen.V342.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V342.Internal.Teleport.Trigger Evergreen.V342.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
