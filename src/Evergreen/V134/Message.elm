module Evergreen.V134.Message exposing (..)

import Evergreen.V134.Emoji
import Evergreen.V134.FileStatus
import Evergreen.V134.Id
import Evergreen.V134.NonemptySet
import Evergreen.V134.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V134.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V134.Emoji.Emoji (Evergreen.V134.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V134.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V134.Id.Id Evergreen.V134.FileStatus.FileId) Evergreen.V134.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V134.Emoji.Emoji (Evergreen.V134.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
