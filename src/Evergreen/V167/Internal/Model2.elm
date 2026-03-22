module Evergreen.V167.Internal.Model2 exposing (..)

import Evergreen.V167.Internal.Teleport
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
    | Teleported Evergreen.V167.Internal.Teleport.Trigger Evergreen.V167.Internal.Teleport.Event
