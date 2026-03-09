module Evergreen.V148.Message exposing (..)

import Evergreen.V148.Emoji
import Evergreen.V148.FileStatus
import Evergreen.V148.Id
import Evergreen.V148.NonemptySet
import Evergreen.V148.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V148.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V148.Emoji.Emoji (Evergreen.V148.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V148.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V148.Id.Id Evergreen.V148.FileStatus.FileId) Evergreen.V148.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V148.Emoji.Emoji (Evergreen.V148.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
