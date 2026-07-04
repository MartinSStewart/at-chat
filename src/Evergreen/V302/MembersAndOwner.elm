module Evergreen.V302.MembersAndOwner exposing (..)

import SeqDict


type MembersAndOwner userId a
    = MembersAndOwner (SeqDict.SeqDict userId a) userId
