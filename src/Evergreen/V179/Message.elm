module Evergreen.V179.Message exposing (..)

import Array
import Evergreen.V179.Embed
import Evergreen.V179.Emoji
import Evergreen.V179.FileStatus
import Evergreen.V179.Id
import Evergreen.V179.NonemptySet
import Evergreen.V179.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V179.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V179.Emoji.Emoji (Evergreen.V179.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V179.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V179.Id.Id Evergreen.V179.FileStatus.FileId) Evergreen.V179.FileStatus.FileData
    , embeds : Array.Array Evergreen.V179.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V179.Emoji.Emoji (Evergreen.V179.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
