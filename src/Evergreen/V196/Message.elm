module Evergreen.V196.Message exposing (..)

import Array
import Evergreen.V196.Embed
import Evergreen.V196.Emoji
import Evergreen.V196.FileStatus
import Evergreen.V196.Id
import Evergreen.V196.NonemptySet
import Evergreen.V196.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V196.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V196.Emoji.Emoji (Evergreen.V196.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V196.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V196.Id.Id Evergreen.V196.FileStatus.FileId) Evergreen.V196.FileStatus.FileData
    , embeds : Array.Array Evergreen.V196.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V196.Emoji.Emoji (Evergreen.V196.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
