module Evergreen.V243.Message exposing (..)

import Array
import Evergreen.V243.Embed
import Evergreen.V243.Emoji
import Evergreen.V243.FileStatus
import Evergreen.V243.Id
import Evergreen.V243.NonemptySet
import Evergreen.V243.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V243.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V243.Emoji.EmojiOrCustomEmoji (Evergreen.V243.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V243.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V243.Id.Id Evergreen.V243.FileStatus.FileId) Evergreen.V243.FileStatus.FileData
    , embeds : Array.Array Evergreen.V243.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V243.Emoji.EmojiOrCustomEmoji (Evergreen.V243.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V243.Emoji.EmojiOrCustomEmoji (Evergreen.V243.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V243.Emoji.EmojiOrCustomEmoji (Evergreen.V243.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V243.Emoji.EmojiOrCustomEmoji (Evergreen.V243.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
