module Evergreen.V116.Internal.Model2 exposing (..)

import Evergreen.V116.Internal.Teleport
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
    | Teleported Evergreen.V116.Internal.Teleport.Trigger Evergreen.V116.Internal.Teleport.Event
