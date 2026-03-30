module Evergreen.V179.MembersAndOwner exposing (..)

import SeqDict


type MembersAndOwner userId a
    = MembersAndOwner (SeqDict.SeqDict userId a) userId
