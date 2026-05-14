module Evergreen.V218.Message exposing (..)

import Array
import Evergreen.V218.Embed
import Evergreen.V218.Emoji
import Evergreen.V218.FileStatus
import Evergreen.V218.Id
import Evergreen.V218.NonemptySet
import Evergreen.V218.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V218.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V218.Emoji.EmojiOrCustomEmoji (Evergreen.V218.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V218.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V218.Id.Id Evergreen.V218.FileStatus.FileId) Evergreen.V218.FileStatus.FileData
    , embeds : Array.Array Evergreen.V218.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V218.Emoji.EmojiOrCustomEmoji (Evergreen.V218.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V218.Emoji.EmojiOrCustomEmoji (Evergreen.V218.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V218.Emoji.EmojiOrCustomEmoji (Evergreen.V218.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V218.Emoji.EmojiOrCustomEmoji (Evergreen.V218.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
