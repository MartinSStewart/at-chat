module Evergreen.V408.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
