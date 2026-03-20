module Evergreen.V160.Message exposing (..)

import Array
import Evergreen.V160.Emoji
import Evergreen.V160.FileStatus
import Evergreen.V160.Id
import Evergreen.V160.NonemptySet
import Evergreen.V160.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V160.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V160.Emoji.Emoji (Evergreen.V160.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V160.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V160.Id.Id Evergreen.V160.FileStatus.FileId) Evergreen.V160.FileStatus.FileData
    , embeds : Array.Array Evergreen.V160.RichText.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V160.Emoji.Emoji (Evergreen.V160.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
