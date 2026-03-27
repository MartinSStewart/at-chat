module Evergreen.V173.Message exposing (..)

import Array
import Evergreen.V173.Embed
import Evergreen.V173.Emoji
import Evergreen.V173.FileStatus
import Evergreen.V173.Id
import Evergreen.V173.NonemptySet
import Evergreen.V173.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V173.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V173.Emoji.Emoji (Evergreen.V173.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V173.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V173.Id.Id Evergreen.V173.FileStatus.FileId) Evergreen.V173.FileStatus.FileData
    , embeds : Array.Array Evergreen.V173.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V173.Emoji.Emoji (Evergreen.V173.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
