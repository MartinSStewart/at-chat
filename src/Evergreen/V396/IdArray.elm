module Evergreen.V396.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
