module Evergreen.V305.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
