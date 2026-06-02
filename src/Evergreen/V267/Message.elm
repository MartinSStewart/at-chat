module Evergreen.V267.Message exposing (..)

import Array
import Evergreen.V267.Embed
import Evergreen.V267.Emoji
import Evergreen.V267.FileStatus
import Evergreen.V267.Id
import Evergreen.V267.NonemptySet
import Evergreen.V267.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V267.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V267.Emoji.EmojiOrCustomEmoji (Evergreen.V267.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V267.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V267.Id.Id Evergreen.V267.FileStatus.FileId) Evergreen.V267.FileStatus.FileData
    , embeds : Array.Array Evergreen.V267.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V267.Emoji.EmojiOrCustomEmoji (Evergreen.V267.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V267.Emoji.EmojiOrCustomEmoji (Evergreen.V267.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V267.Emoji.EmojiOrCustomEmoji (Evergreen.V267.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V267.Emoji.EmojiOrCustomEmoji (Evergreen.V267.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
