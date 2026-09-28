module Evergreen.V389.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
