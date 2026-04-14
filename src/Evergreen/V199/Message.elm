module Evergreen.V199.Message exposing (..)

import Array
import Evergreen.V199.Embed
import Evergreen.V199.Emoji
import Evergreen.V199.FileStatus
import Evergreen.V199.Id
import Evergreen.V199.NonemptySet
import Evergreen.V199.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V199.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V199.Emoji.Emoji (Evergreen.V199.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V199.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V199.Id.Id Evergreen.V199.FileStatus.FileId) Evergreen.V199.FileStatus.FileData
    , embeds : Array.Array Evergreen.V199.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V199.Emoji.Emoji (Evergreen.V199.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
