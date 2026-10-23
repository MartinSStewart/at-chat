module Evergreen.V409.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
