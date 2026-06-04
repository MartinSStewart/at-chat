module Evergreen.V271.Message exposing (..)

import Array
import Evergreen.V271.Embed
import Evergreen.V271.Emoji
import Evergreen.V271.FileStatus
import Evergreen.V271.Id
import Evergreen.V271.NonemptySet
import Evergreen.V271.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V271.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V271.Emoji.EmojiOrCustomEmoji (Evergreen.V271.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V271.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V271.Id.Id Evergreen.V271.FileStatus.FileId) Evergreen.V271.FileStatus.FileData
    , embeds : Array.Array Evergreen.V271.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V271.Emoji.EmojiOrCustomEmoji (Evergreen.V271.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V271.Emoji.EmojiOrCustomEmoji (Evergreen.V271.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V271.Emoji.EmojiOrCustomEmoji (Evergreen.V271.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V271.Emoji.EmojiOrCustomEmoji (Evergreen.V271.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
