module Evergreen.V186.Message exposing (..)

import Array
import Evergreen.V186.Embed
import Evergreen.V186.Emoji
import Evergreen.V186.FileStatus
import Evergreen.V186.Id
import Evergreen.V186.NonemptySet
import Evergreen.V186.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V186.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V186.Emoji.Emoji (Evergreen.V186.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V186.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V186.Id.Id Evergreen.V186.FileStatus.FileId) Evergreen.V186.FileStatus.FileData
    , embeds : Array.Array Evergreen.V186.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V186.Emoji.Emoji (Evergreen.V186.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
