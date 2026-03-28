module Evergreen.V175.Message exposing (..)

import Array
import Evergreen.V175.Embed
import Evergreen.V175.Emoji
import Evergreen.V175.FileStatus
import Evergreen.V175.Id
import Evergreen.V175.NonemptySet
import Evergreen.V175.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V175.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V175.Emoji.Emoji (Evergreen.V175.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V175.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V175.Id.Id Evergreen.V175.FileStatus.FileId) Evergreen.V175.FileStatus.FileData
    , embeds : Array.Array Evergreen.V175.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V175.Emoji.Emoji (Evergreen.V175.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
