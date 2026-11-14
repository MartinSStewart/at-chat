module Evergreen.V422.PeerToPeer exposing (..)

import Effect.File
import Evergreen.V422.FileName
import Evergreen.V422.FileStatus
import Evergreen.V422.Id
import SeqDict
import SeqSet


type alias SharedFile =
    { guildOrDmId : Evergreen.V422.Id.GuildOrDmId
    , fileName : Evergreen.V422.FileName.FileName
    , fileSize : Int
    }


type Download
    = Requested
    | UploaderOffline


type alias Model =
    { shared :
        SeqDict.SeqDict
            Evergreen.V422.FileStatus.PeerToPeerId
            { file : Effect.File.File
            , sharedFile : SharedFile
            }
    , downloads : SeqDict.SeqDict ( Evergreen.V422.Id.Id Evergreen.V422.Id.UserId, Evergreen.V422.FileStatus.PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet.SeqSet Evergreen.V422.FileStatus.PeerToPeerId
    , sending : SeqDict.SeqDict Evergreen.V422.FileStatus.PeerToPeerId Int
    }
