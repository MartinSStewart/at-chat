module Evergreen.V183.Message exposing (..)

import Array
import Evergreen.V183.Embed
import Evergreen.V183.Emoji
import Evergreen.V183.FileStatus
import Evergreen.V183.Id
import Evergreen.V183.NonemptySet
import Evergreen.V183.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V183.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V183.Emoji.Emoji (Evergreen.V183.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V183.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V183.Id.Id Evergreen.V183.FileStatus.FileId) Evergreen.V183.FileStatus.FileData
    , embeds : Array.Array Evergreen.V183.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V183.Emoji.Emoji (Evergreen.V183.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
