module Evergreen.V422.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
