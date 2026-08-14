module Evergreen.V352.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
