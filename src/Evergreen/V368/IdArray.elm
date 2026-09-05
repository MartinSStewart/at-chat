module Evergreen.V368.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
