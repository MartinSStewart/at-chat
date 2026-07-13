module Evergreen.V318.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
