module Evergreen.V349.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
