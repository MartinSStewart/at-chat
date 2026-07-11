module Evergreen.V312.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
