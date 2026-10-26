module Evergreen.V414.IdArray exposing (..)

import Array


type IdArray k v
    = IdArray (Array.Array v)
