module Evergreen.V254.Message exposing (..)

import Array
import Evergreen.V254.Embed
import Evergreen.V254.Emoji
import Evergreen.V254.FileStatus
import Evergreen.V254.Id
import Evergreen.V254.NonemptySet
import Evergreen.V254.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V254.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V254.Emoji.EmojiOrCustomEmoji (Evergreen.V254.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V254.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V254.Id.Id Evergreen.V254.FileStatus.FileId) Evergreen.V254.FileStatus.FileData
    , embeds : Array.Array Evergreen.V254.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V254.Emoji.EmojiOrCustomEmoji (Evergreen.V254.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V254.Emoji.EmojiOrCustomEmoji (Evergreen.V254.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V254.Emoji.EmojiOrCustomEmoji (Evergreen.V254.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V254.Emoji.EmojiOrCustomEmoji (Evergreen.V254.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
