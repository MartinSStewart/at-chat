module Evergreen.V275.Message exposing (..)

import Array
import Evergreen.V275.Embed
import Evergreen.V275.Emoji
import Evergreen.V275.FileStatus
import Evergreen.V275.Id
import Evergreen.V275.NonemptySet
import Evergreen.V275.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V275.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V275.Emoji.EmojiOrCustomEmoji (Evergreen.V275.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V275.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V275.Id.Id Evergreen.V275.FileStatus.FileId) Evergreen.V275.FileStatus.FileData
    , embeds : Array.Array Evergreen.V275.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V275.Emoji.EmojiOrCustomEmoji (Evergreen.V275.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V275.Emoji.EmojiOrCustomEmoji (Evergreen.V275.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V275.Emoji.EmojiOrCustomEmoji (Evergreen.V275.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V275.Emoji.EmojiOrCustomEmoji (Evergreen.V275.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
