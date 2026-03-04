module Evergreen.V128.Message exposing (..)

import Evergreen.V128.Emoji
import Evergreen.V128.FileStatus
import Evergreen.V128.Id
import Evergreen.V128.NonemptySet
import Evergreen.V128.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V128.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V128.Emoji.Emoji (Evergreen.V128.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V128.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V128.Id.Id Evergreen.V128.FileStatus.FileId) Evergreen.V128.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V128.Emoji.Emoji (Evergreen.V128.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
