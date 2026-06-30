module Evergreen.V297.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
