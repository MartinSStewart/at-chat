module Evergreen.V121.Message exposing (..)

import Evergreen.V121.Emoji
import Evergreen.V121.FileStatus
import Evergreen.V121.Id
import Evergreen.V121.NonemptySet
import Evergreen.V121.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V121.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V121.Emoji.Emoji (Evergreen.V121.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V121.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V121.Id.Id Evergreen.V121.FileStatus.FileId) Evergreen.V121.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V121.Emoji.Emoji (Evergreen.V121.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
