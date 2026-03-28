module Evergreen.V176.Internal.Model2 exposing (..)

import Evergreen.V176.Internal.Teleport
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
    | Teleported Evergreen.V176.Internal.Teleport.Trigger Evergreen.V176.Internal.Teleport.Event
