module Evergreen.V425.PeerToPeer exposing (..)

import Effect.File
import Evergreen.V425.FileName
import Evergreen.V425.FileStatus
import Evergreen.V425.Id
import SeqDict
import SeqSet


type alias SharedFile =
    { guildOrDmId : Evergreen.V425.Id.GuildOrDmId
    , fileName : Evergreen.V425.FileName.FileName
    , fileSize : Int
    }


type Download
    = Requested
    | UploaderOffline


type alias Model =
    { shared :
        SeqDict.SeqDict
            Evergreen.V425.FileStatus.PeerToPeerId
            { file : Effect.File.File
            , sharedFile : SharedFile
            }
    , downloads : SeqDict.SeqDict ( Evergreen.V425.Id.Id Evergreen.V425.Id.UserId, Evergreen.V425.FileStatus.PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet.SeqSet Evergreen.V425.FileStatus.PeerToPeerId
    , sending : SeqDict.SeqDict Evergreen.V425.FileStatus.PeerToPeerId Int
    }
