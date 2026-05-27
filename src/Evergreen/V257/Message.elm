module Evergreen.V257.Message exposing (..)

import Array
import Evergreen.V257.Embed
import Evergreen.V257.Emoji
import Evergreen.V257.FileStatus
import Evergreen.V257.Id
import Evergreen.V257.NonemptySet
import Evergreen.V257.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V257.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V257.Emoji.EmojiOrCustomEmoji (Evergreen.V257.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V257.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V257.Id.Id Evergreen.V257.FileStatus.FileId) Evergreen.V257.FileStatus.FileData
    , embeds : Array.Array Evergreen.V257.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V257.Emoji.EmojiOrCustomEmoji (Evergreen.V257.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V257.Emoji.EmojiOrCustomEmoji (Evergreen.V257.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V257.Emoji.EmojiOrCustomEmoji (Evergreen.V257.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V257.Emoji.EmojiOrCustomEmoji (Evergreen.V257.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
