module Evergreen.V395.NonemptySet exposing (..)

import SeqSet


type NonemptySet a
    = NonemptySet a (SeqSet.SeqSet a)
