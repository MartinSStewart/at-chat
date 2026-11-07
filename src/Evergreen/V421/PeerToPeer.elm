module Evergreen.V421.PeerToPeer exposing (..)

import Effect.File
import Evergreen.V421.FileName
import Evergreen.V421.FileStatus
import Evergreen.V421.Id
import SeqDict
import SeqSet


type alias SharedFile =
    { guildOrDmId : Evergreen.V421.Id.GuildOrDmId
    , fileName : Evergreen.V421.FileName.FileName
    , fileSize : Int
    }


type Download
    = Requested
    | UploaderOffline


type alias Model =
    { shared :
        SeqDict.SeqDict
            Evergreen.V421.FileStatus.PeerToPeerId
            { file : Effect.File.File
            , sharedFile : SharedFile
            }
    , downloads : SeqDict.SeqDict ( Evergreen.V421.Id.Id Evergreen.V421.Id.UserId, Evergreen.V421.FileStatus.PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet.SeqSet Evergreen.V421.FileStatus.PeerToPeerId
    , sending : SeqDict.SeqDict Evergreen.V421.FileStatus.PeerToPeerId Int
    }
