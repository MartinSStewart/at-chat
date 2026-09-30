module Evergreen.V395.MembersAndOwner exposing (..)

import SeqDict


type MembersAndOwner userId a
    = MembersAndOwner (SeqDict.SeqDict userId a) userId
