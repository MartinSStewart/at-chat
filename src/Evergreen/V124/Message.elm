module Evergreen.V124.Message exposing (..)

import Evergreen.V124.Emoji
import Evergreen.V124.FileStatus
import Evergreen.V124.Id
import Evergreen.V124.NonemptySet
import Evergreen.V124.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V124.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V124.Emoji.Emoji (Evergreen.V124.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V124.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V124.Id.Id Evergreen.V124.FileStatus.FileId) Evergreen.V124.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V124.Emoji.Emoji (Evergreen.V124.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
