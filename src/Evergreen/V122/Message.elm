module Evergreen.V122.Message exposing (..)

import Evergreen.V122.Emoji
import Evergreen.V122.FileStatus
import Evergreen.V122.Id
import Evergreen.V122.NonemptySet
import Evergreen.V122.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V122.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V122.Emoji.Emoji (Evergreen.V122.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V122.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V122.Id.Id Evergreen.V122.FileStatus.FileId) Evergreen.V122.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V122.Emoji.Emoji (Evergreen.V122.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
