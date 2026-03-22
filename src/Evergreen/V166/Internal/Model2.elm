module Evergreen.V166.Internal.Model2 exposing (..)

import Evergreen.V166.Internal.Teleport
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
    | Teleported Evergreen.V166.Internal.Teleport.Trigger Evergreen.V166.Internal.Teleport.Event
