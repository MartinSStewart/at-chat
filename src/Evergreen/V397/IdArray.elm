module Evergreen.V397.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
