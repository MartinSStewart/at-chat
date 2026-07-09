module Evergreen.V309.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
