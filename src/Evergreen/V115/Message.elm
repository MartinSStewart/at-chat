module Evergreen.V115.Message exposing (..)

import Evergreen.V115.Emoji
import Evergreen.V115.FileStatus
import Evergreen.V115.Id
import Evergreen.V115.NonemptySet
import Evergreen.V115.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V115.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V115.Emoji.Emoji (Evergreen.V115.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V115.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V115.Id.Id Evergreen.V115.FileStatus.FileId) Evergreen.V115.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V115.Emoji.Emoji (Evergreen.V115.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
