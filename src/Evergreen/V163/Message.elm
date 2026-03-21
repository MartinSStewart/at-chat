module Evergreen.V163.Message exposing (..)

import Array
import Evergreen.V163.Emoji
import Evergreen.V163.FileStatus
import Evergreen.V163.Id
import Evergreen.V163.NonemptySet
import Evergreen.V163.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V163.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V163.Emoji.Emoji (Evergreen.V163.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V163.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V163.Id.Id Evergreen.V163.FileStatus.FileId) Evergreen.V163.FileStatus.FileData
    , embeds : Array.Array Evergreen.V163.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V163.Emoji.Emoji (Evergreen.V163.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
