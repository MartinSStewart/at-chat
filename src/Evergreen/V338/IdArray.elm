module Evergreen.V338.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
