module Evergreen.V266.Message exposing (..)

import Array
import Evergreen.V266.Embed
import Evergreen.V266.Emoji
import Evergreen.V266.FileStatus
import Evergreen.V266.Id
import Evergreen.V266.NonemptySet
import Evergreen.V266.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V266.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V266.Emoji.EmojiOrCustomEmoji (Evergreen.V266.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V266.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V266.Id.Id Evergreen.V266.FileStatus.FileId) Evergreen.V266.FileStatus.FileData
    , embeds : Array.Array Evergreen.V266.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V266.Emoji.EmojiOrCustomEmoji (Evergreen.V266.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V266.Emoji.EmojiOrCustomEmoji (Evergreen.V266.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V266.Emoji.EmojiOrCustomEmoji (Evergreen.V266.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V266.Emoji.EmojiOrCustomEmoji (Evergreen.V266.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
