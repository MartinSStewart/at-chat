module Evergreen.V187.Message exposing (..)

import Array
import Evergreen.V187.Embed
import Evergreen.V187.Emoji
import Evergreen.V187.FileStatus
import Evergreen.V187.Id
import Evergreen.V187.NonemptySet
import Evergreen.V187.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V187.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V187.Emoji.Emoji (Evergreen.V187.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V187.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V187.Id.Id Evergreen.V187.FileStatus.FileId) Evergreen.V187.FileStatus.FileData
    , embeds : Array.Array Evergreen.V187.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V187.Emoji.Emoji (Evergreen.V187.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
