module Evergreen.V169.Message exposing (..)

import Array
import Evergreen.V169.Embed
import Evergreen.V169.Emoji
import Evergreen.V169.FileStatus
import Evergreen.V169.Id
import Evergreen.V169.NonemptySet
import Evergreen.V169.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V169.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V169.Emoji.Emoji (Evergreen.V169.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V169.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V169.Id.Id Evergreen.V169.FileStatus.FileId) Evergreen.V169.FileStatus.FileData
    , embeds : Array.Array Evergreen.V169.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V169.Emoji.Emoji (Evergreen.V169.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
