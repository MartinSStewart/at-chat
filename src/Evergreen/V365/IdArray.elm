module Evergreen.V365.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
