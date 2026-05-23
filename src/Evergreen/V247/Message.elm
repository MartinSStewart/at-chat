module Evergreen.V247.Message exposing (..)

import Array
import Evergreen.V247.Embed
import Evergreen.V247.Emoji
import Evergreen.V247.FileStatus
import Evergreen.V247.Id
import Evergreen.V247.NonemptySet
import Evergreen.V247.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V247.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V247.Emoji.EmojiOrCustomEmoji (Evergreen.V247.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V247.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V247.Id.Id Evergreen.V247.FileStatus.FileId) Evergreen.V247.FileStatus.FileData
    , embeds : Array.Array Evergreen.V247.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V247.Emoji.EmojiOrCustomEmoji (Evergreen.V247.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V247.Emoji.EmojiOrCustomEmoji (Evergreen.V247.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V247.Emoji.EmojiOrCustomEmoji (Evergreen.V247.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V247.Emoji.EmojiOrCustomEmoji (Evergreen.V247.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
