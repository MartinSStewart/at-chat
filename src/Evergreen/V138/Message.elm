module Evergreen.V138.Message exposing (..)

import Evergreen.V138.Emoji
import Evergreen.V138.FileStatus
import Evergreen.V138.Id
import Evergreen.V138.NonemptySet
import Evergreen.V138.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V138.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V138.Emoji.Emoji (Evergreen.V138.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V138.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V138.Id.Id Evergreen.V138.FileStatus.FileId) Evergreen.V138.FileStatus.FileData
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V138.Emoji.Emoji (Evergreen.V138.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
