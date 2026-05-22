module Evergreen.V242.Message exposing (..)

import Array
import Evergreen.V242.Embed
import Evergreen.V242.Emoji
import Evergreen.V242.FileStatus
import Evergreen.V242.Id
import Evergreen.V242.NonemptySet
import Evergreen.V242.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V242.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V242.Emoji.EmojiOrCustomEmoji (Evergreen.V242.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V242.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V242.Id.Id Evergreen.V242.FileStatus.FileId) Evergreen.V242.FileStatus.FileData
    , embeds : Array.Array Evergreen.V242.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V242.Emoji.EmojiOrCustomEmoji (Evergreen.V242.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V242.Emoji.EmojiOrCustomEmoji (Evergreen.V242.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V242.Emoji.EmojiOrCustomEmoji (Evergreen.V242.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V242.Emoji.EmojiOrCustomEmoji (Evergreen.V242.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
