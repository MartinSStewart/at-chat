module Evergreen.V360.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
