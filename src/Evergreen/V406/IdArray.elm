module Evergreen.V406.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
