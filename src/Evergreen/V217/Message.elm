module Evergreen.V217.Message exposing (..)

import Array
import Evergreen.V217.Embed
import Evergreen.V217.Emoji
import Evergreen.V217.FileStatus
import Evergreen.V217.Id
import Evergreen.V217.NonemptySet
import Evergreen.V217.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V217.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V217.Emoji.EmojiOrCustomEmoji (Evergreen.V217.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V217.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V217.Id.Id Evergreen.V217.FileStatus.FileId) Evergreen.V217.FileStatus.FileData
    , embeds : Array.Array Evergreen.V217.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V217.Emoji.EmojiOrCustomEmoji (Evergreen.V217.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V217.Emoji.EmojiOrCustomEmoji (Evergreen.V217.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V217.Emoji.EmojiOrCustomEmoji (Evergreen.V217.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V217.Emoji.EmojiOrCustomEmoji (Evergreen.V217.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
