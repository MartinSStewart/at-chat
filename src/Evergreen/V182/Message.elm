module Evergreen.V182.Message exposing (..)

import Array
import Evergreen.V182.Embed
import Evergreen.V182.Emoji
import Evergreen.V182.FileStatus
import Evergreen.V182.Id
import Evergreen.V182.NonemptySet
import Evergreen.V182.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V182.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V182.Emoji.Emoji (Evergreen.V182.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V182.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V182.Id.Id Evergreen.V182.FileStatus.FileId) Evergreen.V182.FileStatus.FileData
    , embeds : Array.Array Evergreen.V182.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V182.Emoji.Emoji (Evergreen.V182.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
