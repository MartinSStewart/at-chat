module Evergreen.V423.PeerToPeer exposing (..)

import Effect.File
import Evergreen.V423.FileName
import Evergreen.V423.FileStatus
import Evergreen.V423.Id
import SeqDict
import SeqSet


type alias SharedFile =
    { guildOrDmId : Evergreen.V423.Id.GuildOrDmId
    , fileName : Evergreen.V423.FileName.FileName
    , fileSize : Int
    }


type Download
    = Requested
    | UploaderOffline


type alias Model =
    { shared :
        SeqDict.SeqDict
            Evergreen.V423.FileStatus.PeerToPeerId
            { file : Effect.File.File
            , sharedFile : SharedFile
            }
    , downloads : SeqDict.SeqDict ( Evergreen.V423.Id.Id Evergreen.V423.Id.UserId, Evergreen.V423.FileStatus.PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet.SeqSet Evergreen.V423.FileStatus.PeerToPeerId
    , sending : SeqDict.SeqDict Evergreen.V423.FileStatus.PeerToPeerId Int
    }
