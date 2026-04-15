module Evergreen.V201.Message exposing (..)

import Array
import Evergreen.V201.Embed
import Evergreen.V201.Emoji
import Evergreen.V201.FileStatus
import Evergreen.V201.Id
import Evergreen.V201.NonemptySet
import Evergreen.V201.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V201.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V201.Emoji.Emoji (Evergreen.V201.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V201.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V201.Id.Id Evergreen.V201.FileStatus.FileId) Evergreen.V201.FileStatus.FileData
    , embeds : Array.Array Evergreen.V201.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V201.Emoji.Emoji (Evergreen.V201.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
