module Evergreen.V277.Message exposing (..)

import Array
import Evergreen.V277.Embed
import Evergreen.V277.Emoji
import Evergreen.V277.FileStatus
import Evergreen.V277.Id
import Evergreen.V277.NonemptySet
import Evergreen.V277.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V277.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V277.Emoji.EmojiOrCustomEmoji (Evergreen.V277.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V277.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V277.Id.Id Evergreen.V277.FileStatus.FileId) Evergreen.V277.FileStatus.FileData
    , embeds : Array.Array Evergreen.V277.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V277.Emoji.EmojiOrCustomEmoji (Evergreen.V277.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V277.Emoji.EmojiOrCustomEmoji (Evergreen.V277.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V277.Emoji.EmojiOrCustomEmoji (Evergreen.V277.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V277.Emoji.EmojiOrCustomEmoji (Evergreen.V277.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
