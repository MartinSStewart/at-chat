module Evergreen.V311.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
