module Evergreen.V223.Message exposing (..)

import Array
import Evergreen.V223.Embed
import Evergreen.V223.Emoji
import Evergreen.V223.FileStatus
import Evergreen.V223.Id
import Evergreen.V223.NonemptySet
import Evergreen.V223.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V223.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V223.Emoji.EmojiOrCustomEmoji (Evergreen.V223.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V223.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V223.Id.Id Evergreen.V223.FileStatus.FileId) Evergreen.V223.FileStatus.FileData
    , embeds : Array.Array Evergreen.V223.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V223.Emoji.EmojiOrCustomEmoji (Evergreen.V223.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V223.Emoji.EmojiOrCustomEmoji (Evergreen.V223.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V223.Emoji.EmojiOrCustomEmoji (Evergreen.V223.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V223.Emoji.EmojiOrCustomEmoji (Evergreen.V223.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
