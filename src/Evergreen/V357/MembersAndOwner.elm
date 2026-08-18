module Evergreen.V357.MembersAndOwner exposing (..)

import SeqDict


type MembersAndOwner userId a
    = MembersAndOwner (SeqDict.SeqDict userId a) userId
