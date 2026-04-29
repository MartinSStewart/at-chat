module Evergreen.V211.Message exposing (..)

import Array
import Evergreen.V211.Embed
import Evergreen.V211.Emoji
import Evergreen.V211.FileStatus
import Evergreen.V211.Id
import Evergreen.V211.NonemptySet
import Evergreen.V211.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V211.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V211.Emoji.EmojiOrCustomEmoji (Evergreen.V211.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V211.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V211.Id.Id Evergreen.V211.FileStatus.FileId) Evergreen.V211.FileStatus.FileData
    , embeds : Array.Array Evergreen.V211.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V211.Emoji.EmojiOrCustomEmoji (Evergreen.V211.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
