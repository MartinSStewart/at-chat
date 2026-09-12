module Evergreen.V379.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
