module Evergreen.V397.Internal.Model2 exposing (..)

import Evergreen.V397.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V397.Internal.Teleport.Trigger Evergreen.V397.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
