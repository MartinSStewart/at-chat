module Evergreen.V209.Internal.Model2 exposing (..)

import Evergreen.V209.Internal.Teleport
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
    | Teleported Evergreen.V209.Internal.Teleport.Trigger Evergreen.V209.Internal.Teleport.Event
