module Evergreen.V426.PeerToPeer exposing (..)

import Effect.File
import Evergreen.V426.FileName
import Evergreen.V426.FileStatus
import Evergreen.V426.Id
import SeqDict
import SeqSet


type alias SharedFile =
    { guildOrDmId : Evergreen.V426.Id.GuildOrDmId
    , fileName : Evergreen.V426.FileName.FileName
    , fileSize : Int
    }


type Download
    = Requested
    | UploaderOffline


type alias Model =
    { shared :
        SeqDict.SeqDict
            Evergreen.V426.FileStatus.PeerToPeerId
            { file : Effect.File.File
            , sharedFile : SharedFile
            }
    , downloads : SeqDict.SeqDict ( Evergreen.V426.Id.Id Evergreen.V426.Id.UserId, Evergreen.V426.FileStatus.PeerToPeerId ) Download
    , pickedDifferentFile : SeqSet.SeqSet Evergreen.V426.FileStatus.PeerToPeerId
    , sending : SeqDict.SeqDict Evergreen.V426.FileStatus.PeerToPeerId Int
    }
