module Evergreen.V112.Message exposing (..)

import Evergreen.V112.Emoji
import Evergreen.V112.FileStatus
import Evergreen.V112.Id
import Evergreen.V112.NonemptySet
import Evergreen.V112.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V112.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V112.Emoji.Emoji (Evergreen.V112.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V112.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V112.Id.Id Evergreen.V112.FileStatus.FileId) Evergreen.V112.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V112.Emoji.Emoji (Evergreen.V112.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
