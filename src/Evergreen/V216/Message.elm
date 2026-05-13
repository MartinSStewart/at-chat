module Evergreen.V216.Message exposing (..)

import Array
import Evergreen.V216.Embed
import Evergreen.V216.Emoji
import Evergreen.V216.FileStatus
import Evergreen.V216.Id
import Evergreen.V216.NonemptySet
import Evergreen.V216.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V216.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V216.Emoji.EmojiOrCustomEmoji (Evergreen.V216.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V216.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V216.Id.Id Evergreen.V216.FileStatus.FileId) Evergreen.V216.FileStatus.FileData
    , embeds : Array.Array Evergreen.V216.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V216.Emoji.EmojiOrCustomEmoji (Evergreen.V216.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V216.Emoji.EmojiOrCustomEmoji (Evergreen.V216.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V216.Emoji.EmojiOrCustomEmoji (Evergreen.V216.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V216.Emoji.EmojiOrCustomEmoji (Evergreen.V216.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
