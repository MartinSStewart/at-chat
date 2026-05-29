module Evergreen.V261.Message exposing (..)

import Array
import Evergreen.V261.Embed
import Evergreen.V261.Emoji
import Evergreen.V261.FileStatus
import Evergreen.V261.Id
import Evergreen.V261.NonemptySet
import Evergreen.V261.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V261.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V261.Emoji.EmojiOrCustomEmoji (Evergreen.V261.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V261.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V261.Id.Id Evergreen.V261.FileStatus.FileId) Evergreen.V261.FileStatus.FileData
    , embeds : Array.Array Evergreen.V261.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V261.Emoji.EmojiOrCustomEmoji (Evergreen.V261.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V261.Emoji.EmojiOrCustomEmoji (Evergreen.V261.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V261.Emoji.EmojiOrCustomEmoji (Evergreen.V261.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V261.Emoji.EmojiOrCustomEmoji (Evergreen.V261.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
