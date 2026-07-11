module Evergreen.V315.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
