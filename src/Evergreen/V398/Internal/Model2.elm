module Evergreen.V398.Internal.Model2 exposing (..)

import Evergreen.V398.Internal.Teleport
import Set
import Time


type Msg
    = Tick Time.Posix
    | Teleported Evergreen.V398.Internal.Teleport.Trigger Evergreen.V398.Internal.Teleport.Event


type State
    = State
        { added : Set.Set String
        , rules : List String
        , keyframes : List String
        }
