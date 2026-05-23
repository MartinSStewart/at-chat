module Evergreen.V248.Message exposing (..)

import Array
import Evergreen.V248.Embed
import Evergreen.V248.Emoji
import Evergreen.V248.FileStatus
import Evergreen.V248.Id
import Evergreen.V248.NonemptySet
import Evergreen.V248.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V248.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V248.Emoji.EmojiOrCustomEmoji (Evergreen.V248.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V248.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V248.Id.Id Evergreen.V248.FileStatus.FileId) Evergreen.V248.FileStatus.FileData
    , embeds : Array.Array Evergreen.V248.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V248.Emoji.EmojiOrCustomEmoji (Evergreen.V248.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V248.Emoji.EmojiOrCustomEmoji (Evergreen.V248.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V248.Emoji.EmojiOrCustomEmoji (Evergreen.V248.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V248.Emoji.EmojiOrCustomEmoji (Evergreen.V248.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
