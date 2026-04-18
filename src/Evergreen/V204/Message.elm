module Evergreen.V204.Message exposing (..)

import Array
import Evergreen.V204.Embed
import Evergreen.V204.Emoji
import Evergreen.V204.FileStatus
import Evergreen.V204.Id
import Evergreen.V204.NonemptySet
import Evergreen.V204.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V204.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V204.Emoji.Emoji (Evergreen.V204.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V204.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V204.Id.Id Evergreen.V204.FileStatus.FileId) Evergreen.V204.FileStatus.FileData
    , embeds : Array.Array Evergreen.V204.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V204.Emoji.Emoji (Evergreen.V204.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
