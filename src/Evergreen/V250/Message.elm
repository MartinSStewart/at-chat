module Evergreen.V250.Message exposing (..)

import Array
import Evergreen.V250.Embed
import Evergreen.V250.Emoji
import Evergreen.V250.FileStatus
import Evergreen.V250.Id
import Evergreen.V250.NonemptySet
import Evergreen.V250.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V250.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V250.Emoji.EmojiOrCustomEmoji (Evergreen.V250.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V250.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V250.Id.Id Evergreen.V250.FileStatus.FileId) Evergreen.V250.FileStatus.FileData
    , embeds : Array.Array Evergreen.V250.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V250.Emoji.EmojiOrCustomEmoji (Evergreen.V250.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V250.Emoji.EmojiOrCustomEmoji (Evergreen.V250.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V250.Emoji.EmojiOrCustomEmoji (Evergreen.V250.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V250.Emoji.EmojiOrCustomEmoji (Evergreen.V250.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
