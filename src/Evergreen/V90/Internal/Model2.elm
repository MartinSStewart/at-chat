module Evergreen.V90.Internal.Model2 exposing (..)

import Evergreen.V90.Internal.Teleport
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
    | Teleported Evergreen.V90.Internal.Teleport.Trigger Evergreen.V90.Internal.Teleport.Event
