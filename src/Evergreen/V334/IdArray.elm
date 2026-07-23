module Evergreen.V334.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
