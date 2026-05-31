module Evergreen.V263.Message exposing (..)

import Array
import Evergreen.V263.Embed
import Evergreen.V263.Emoji
import Evergreen.V263.FileStatus
import Evergreen.V263.Id
import Evergreen.V263.NonemptySet
import Evergreen.V263.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V263.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V263.Emoji.EmojiOrCustomEmoji (Evergreen.V263.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V263.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V263.Id.Id Evergreen.V263.FileStatus.FileId) Evergreen.V263.FileStatus.FileData
    , embeds : Array.Array Evergreen.V263.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V263.Emoji.EmojiOrCustomEmoji (Evergreen.V263.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V263.Emoji.EmojiOrCustomEmoji (Evergreen.V263.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V263.Emoji.EmojiOrCustomEmoji (Evergreen.V263.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V263.Emoji.EmojiOrCustomEmoji (Evergreen.V263.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
