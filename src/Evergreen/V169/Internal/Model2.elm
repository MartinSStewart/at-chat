module Evergreen.V169.Internal.Model2 exposing (..)

import Evergreen.V169.Internal.Teleport
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
    | Teleported Evergreen.V169.Internal.Teleport.Trigger Evergreen.V169.Internal.Teleport.Event
