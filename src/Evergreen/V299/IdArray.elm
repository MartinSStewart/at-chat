module Evergreen.V299.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
