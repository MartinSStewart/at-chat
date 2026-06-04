module Evergreen.V273.Message exposing (..)

import Array
import Evergreen.V273.Embed
import Evergreen.V273.Emoji
import Evergreen.V273.FileStatus
import Evergreen.V273.Id
import Evergreen.V273.NonemptySet
import Evergreen.V273.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V273.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V273.Emoji.EmojiOrCustomEmoji (Evergreen.V273.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V273.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V273.Id.Id Evergreen.V273.FileStatus.FileId) Evergreen.V273.FileStatus.FileData
    , embeds : Array.Array Evergreen.V273.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V273.Emoji.EmojiOrCustomEmoji (Evergreen.V273.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V273.Emoji.EmojiOrCustomEmoji (Evergreen.V273.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V273.Emoji.EmojiOrCustomEmoji (Evergreen.V273.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V273.Emoji.EmojiOrCustomEmoji (Evergreen.V273.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
