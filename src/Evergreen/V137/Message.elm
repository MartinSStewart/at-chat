module Evergreen.V137.Message exposing (..)

import Evergreen.V137.Emoji
import Evergreen.V137.FileStatus
import Evergreen.V137.Id
import Evergreen.V137.NonemptySet
import Evergreen.V137.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V137.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V137.Emoji.Emoji (Evergreen.V137.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V137.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V137.Id.Id Evergreen.V137.FileStatus.FileId) Evergreen.V137.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V137.Emoji.Emoji (Evergreen.V137.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
