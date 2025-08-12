module Evergreen.V23.NonemptyDict exposing (..)

import SeqDict


type NonemptyDict id a
    = NonemptyDict id a (SeqDict.SeqDict id a)
