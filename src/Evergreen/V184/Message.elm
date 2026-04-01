module Evergreen.V184.Message exposing (..)

import Array
import Evergreen.V184.Embed
import Evergreen.V184.Emoji
import Evergreen.V184.FileStatus
import Evergreen.V184.Id
import Evergreen.V184.NonemptySet
import Evergreen.V184.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V184.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V184.Emoji.Emoji (Evergreen.V184.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V184.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V184.Id.Id Evergreen.V184.FileStatus.FileId) Evergreen.V184.FileStatus.FileData
    , embeds : Array.Array Evergreen.V184.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V184.Emoji.Emoji (Evergreen.V184.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
