module Evergreen.V405.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
