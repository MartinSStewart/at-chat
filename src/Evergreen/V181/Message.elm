module Evergreen.V181.Message exposing (..)

import Array
import Evergreen.V181.Embed
import Evergreen.V181.Emoji
import Evergreen.V181.FileStatus
import Evergreen.V181.Id
import Evergreen.V181.NonemptySet
import Evergreen.V181.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V181.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V181.Emoji.Emoji (Evergreen.V181.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V181.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V181.Id.Id Evergreen.V181.FileStatus.FileId) Evergreen.V181.FileStatus.FileData
    , embeds : Array.Array Evergreen.V181.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V181.Emoji.Emoji (Evergreen.V181.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
