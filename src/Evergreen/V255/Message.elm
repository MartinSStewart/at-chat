module Evergreen.V255.Message exposing (..)

import Array
import Evergreen.V255.Embed
import Evergreen.V255.Emoji
import Evergreen.V255.FileStatus
import Evergreen.V255.Id
import Evergreen.V255.NonemptySet
import Evergreen.V255.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V255.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V255.Emoji.EmojiOrCustomEmoji (Evergreen.V255.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V255.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V255.Id.Id Evergreen.V255.FileStatus.FileId) Evergreen.V255.FileStatus.FileData
    , embeds : Array.Array Evergreen.V255.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V255.Emoji.EmojiOrCustomEmoji (Evergreen.V255.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V255.Emoji.EmojiOrCustomEmoji (Evergreen.V255.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V255.Emoji.EmojiOrCustomEmoji (Evergreen.V255.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V255.Emoji.EmojiOrCustomEmoji (Evergreen.V255.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
