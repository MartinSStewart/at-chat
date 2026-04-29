module Evergreen.V209.Message exposing (..)

import Array
import Evergreen.V209.Embed
import Evergreen.V209.Emoji
import Evergreen.V209.FileStatus
import Evergreen.V209.Id
import Evergreen.V209.NonemptySet
import Evergreen.V209.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V209.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V209.Emoji.Emoji (Evergreen.V209.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V209.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V209.Id.Id Evergreen.V209.FileStatus.FileId) Evergreen.V209.FileStatus.FileData
    , embeds : Array.Array Evergreen.V209.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V209.Emoji.Emoji (Evergreen.V209.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
