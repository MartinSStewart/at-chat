module Evergreen.V264.Message exposing (..)

import Array
import Evergreen.V264.Embed
import Evergreen.V264.Emoji
import Evergreen.V264.FileStatus
import Evergreen.V264.Id
import Evergreen.V264.NonemptySet
import Evergreen.V264.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V264.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V264.Emoji.EmojiOrCustomEmoji (Evergreen.V264.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V264.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V264.Id.Id Evergreen.V264.FileStatus.FileId) Evergreen.V264.FileStatus.FileData
    , embeds : Array.Array Evergreen.V264.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V264.Emoji.EmojiOrCustomEmoji (Evergreen.V264.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V264.Emoji.EmojiOrCustomEmoji (Evergreen.V264.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V264.Emoji.EmojiOrCustomEmoji (Evergreen.V264.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V264.Emoji.EmojiOrCustomEmoji (Evergreen.V264.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
