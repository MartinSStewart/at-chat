module Evergreen.V372.Internal.Model2 exposing (..)

import Evergreen.V372.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V372.Internal.Teleport.Trigger Evergreen.V372.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
