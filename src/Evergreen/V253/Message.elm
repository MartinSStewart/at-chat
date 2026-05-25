module Evergreen.V253.Message exposing (..)

import Array
import Evergreen.V253.Embed
import Evergreen.V253.Emoji
import Evergreen.V253.FileStatus
import Evergreen.V253.Id
import Evergreen.V253.NonemptySet
import Evergreen.V253.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V253.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V253.Emoji.EmojiOrCustomEmoji (Evergreen.V253.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V253.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V253.Id.Id Evergreen.V253.FileStatus.FileId) Evergreen.V253.FileStatus.FileData
    , embeds : Array.Array Evergreen.V253.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V253.Emoji.EmojiOrCustomEmoji (Evergreen.V253.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V253.Emoji.EmojiOrCustomEmoji (Evergreen.V253.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V253.Emoji.EmojiOrCustomEmoji (Evergreen.V253.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V253.Emoji.EmojiOrCustomEmoji (Evergreen.V253.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
