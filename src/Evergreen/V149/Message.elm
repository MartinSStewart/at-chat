module Evergreen.V149.Message exposing (..)

import Evergreen.V149.Emoji
import Evergreen.V149.FileStatus
import Evergreen.V149.Id
import Evergreen.V149.NonemptySet
import Evergreen.V149.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V149.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V149.Emoji.Emoji (Evergreen.V149.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V149.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V149.Id.Id Evergreen.V149.FileStatus.FileId) Evergreen.V149.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V149.Emoji.Emoji (Evergreen.V149.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
