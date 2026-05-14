module Evergreen.V217.OneToOne exposing (..)

import SeqDict


type OneToOne a b
    = OneToOne (SeqDict.SeqDict a b) (SeqDict.SeqDict b a)
