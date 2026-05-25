module Evergreen.V252.Message exposing (..)

import Array
import Evergreen.V252.Embed
import Evergreen.V252.Emoji
import Evergreen.V252.FileStatus
import Evergreen.V252.Id
import Evergreen.V252.NonemptySet
import Evergreen.V252.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V252.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V252.Emoji.EmojiOrCustomEmoji (Evergreen.V252.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V252.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V252.Id.Id Evergreen.V252.FileStatus.FileId) Evergreen.V252.FileStatus.FileData
    , embeds : Array.Array Evergreen.V252.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V252.Emoji.EmojiOrCustomEmoji (Evergreen.V252.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V252.Emoji.EmojiOrCustomEmoji (Evergreen.V252.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V252.Emoji.EmojiOrCustomEmoji (Evergreen.V252.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V252.Emoji.EmojiOrCustomEmoji (Evergreen.V252.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
