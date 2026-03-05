module Evergreen.V135.Message exposing (..)

import Evergreen.V135.Emoji
import Evergreen.V135.FileStatus
import Evergreen.V135.Id
import Evergreen.V135.NonemptySet
import Evergreen.V135.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V135.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V135.Emoji.Emoji (Evergreen.V135.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V135.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V135.Id.Id Evergreen.V135.FileStatus.FileId) Evergreen.V135.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V135.Emoji.Emoji (Evergreen.V135.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
