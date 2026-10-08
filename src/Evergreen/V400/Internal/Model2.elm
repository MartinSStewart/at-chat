module Evergreen.V400.Internal.Model2 exposing (..)

import Evergreen.V400.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V400.Internal.Teleport.Trigger Evergreen.V400.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
