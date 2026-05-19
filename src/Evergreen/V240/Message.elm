module Evergreen.V240.Message exposing (..)

import Array
import Evergreen.V240.Embed
import Evergreen.V240.Emoji
import Evergreen.V240.FileStatus
import Evergreen.V240.Id
import Evergreen.V240.NonemptySet
import Evergreen.V240.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V240.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V240.Emoji.EmojiOrCustomEmoji (Evergreen.V240.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V240.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V240.Id.Id Evergreen.V240.FileStatus.FileId) Evergreen.V240.FileStatus.FileData
    , embeds : Array.Array Evergreen.V240.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V240.Emoji.EmojiOrCustomEmoji (Evergreen.V240.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V240.Emoji.EmojiOrCustomEmoji (Evergreen.V240.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V240.Emoji.EmojiOrCustomEmoji (Evergreen.V240.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V240.Emoji.EmojiOrCustomEmoji (Evergreen.V240.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
