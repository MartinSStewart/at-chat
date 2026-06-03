module Evergreen.V269.Message exposing (..)

import Array
import Evergreen.V269.Embed
import Evergreen.V269.Emoji
import Evergreen.V269.FileStatus
import Evergreen.V269.Id
import Evergreen.V269.NonemptySet
import Evergreen.V269.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V269.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V269.Emoji.EmojiOrCustomEmoji (Evergreen.V269.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V269.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V269.Id.Id Evergreen.V269.FileStatus.FileId) Evergreen.V269.FileStatus.FileData
    , embeds : Array.Array Evergreen.V269.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V269.Emoji.EmojiOrCustomEmoji (Evergreen.V269.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V269.Emoji.EmojiOrCustomEmoji (Evergreen.V269.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V269.Emoji.EmojiOrCustomEmoji (Evergreen.V269.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V269.Emoji.EmojiOrCustomEmoji (Evergreen.V269.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
