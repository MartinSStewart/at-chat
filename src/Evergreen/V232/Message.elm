module Evergreen.V232.Message exposing (..)

import Array
import Evergreen.V232.Embed
import Evergreen.V232.Emoji
import Evergreen.V232.FileStatus
import Evergreen.V232.Id
import Evergreen.V232.NonemptySet
import Evergreen.V232.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V232.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V232.Emoji.EmojiOrCustomEmoji (Evergreen.V232.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V232.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V232.Id.Id Evergreen.V232.FileStatus.FileId) Evergreen.V232.FileStatus.FileData
    , embeds : Array.Array Evergreen.V232.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V232.Emoji.EmojiOrCustomEmoji (Evergreen.V232.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V232.Emoji.EmojiOrCustomEmoji (Evergreen.V232.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V232.Emoji.EmojiOrCustomEmoji (Evergreen.V232.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V232.Emoji.EmojiOrCustomEmoji (Evergreen.V232.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
