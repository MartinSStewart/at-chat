module Evergreen.V279.Message exposing (..)

import Array
import Evergreen.V279.Embed
import Evergreen.V279.Emoji
import Evergreen.V279.FileStatus
import Evergreen.V279.Id
import Evergreen.V279.NonemptySet
import Evergreen.V279.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V279.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V279.Emoji.EmojiOrCustomEmoji (Evergreen.V279.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V279.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V279.Id.Id Evergreen.V279.FileStatus.FileId) Evergreen.V279.FileStatus.FileData
    , embeds : Array.Array Evergreen.V279.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V279.Emoji.EmojiOrCustomEmoji (Evergreen.V279.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V279.Emoji.EmojiOrCustomEmoji (Evergreen.V279.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V279.Emoji.EmojiOrCustomEmoji (Evergreen.V279.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V279.Emoji.EmojiOrCustomEmoji (Evergreen.V279.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
