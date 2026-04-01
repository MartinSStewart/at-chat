module Evergreen.V185.Message exposing (..)

import Array
import Evergreen.V185.Embed
import Evergreen.V185.Emoji
import Evergreen.V185.FileStatus
import Evergreen.V185.Id
import Evergreen.V185.NonemptySet
import Evergreen.V185.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V185.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V185.Emoji.Emoji (Evergreen.V185.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V185.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V185.Id.Id Evergreen.V185.FileStatus.FileId) Evergreen.V185.FileStatus.FileData
    , embeds : Array.Array Evergreen.V185.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V185.Emoji.Emoji (Evergreen.V185.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
