module Evergreen.V206.Message exposing (..)

import Array
import Evergreen.V206.Embed
import Evergreen.V206.Emoji
import Evergreen.V206.FileStatus
import Evergreen.V206.Id
import Evergreen.V206.NonemptySet
import Evergreen.V206.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V206.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V206.Emoji.Emoji (Evergreen.V206.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V206.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V206.Id.Id Evergreen.V206.FileStatus.FileId) Evergreen.V206.FileStatus.FileData
    , embeds : Array.Array Evergreen.V206.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V206.Emoji.Emoji (Evergreen.V206.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
