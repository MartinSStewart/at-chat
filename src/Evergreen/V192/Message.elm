module Evergreen.V192.Message exposing (..)

import Array
import Evergreen.V192.Embed
import Evergreen.V192.Emoji
import Evergreen.V192.FileStatus
import Evergreen.V192.Id
import Evergreen.V192.NonemptySet
import Evergreen.V192.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V192.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V192.Emoji.Emoji (Evergreen.V192.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V192.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V192.Id.Id Evergreen.V192.FileStatus.FileId) Evergreen.V192.FileStatus.FileData
    , embeds : Array.Array Evergreen.V192.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V192.Emoji.Emoji (Evergreen.V192.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
