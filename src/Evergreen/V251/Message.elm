module Evergreen.V251.Message exposing (..)

import Array
import Evergreen.V251.Embed
import Evergreen.V251.Emoji
import Evergreen.V251.FileStatus
import Evergreen.V251.Id
import Evergreen.V251.NonemptySet
import Evergreen.V251.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V251.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V251.Emoji.EmojiOrCustomEmoji (Evergreen.V251.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V251.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V251.Id.Id Evergreen.V251.FileStatus.FileId) Evergreen.V251.FileStatus.FileData
    , embeds : Array.Array Evergreen.V251.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V251.Emoji.EmojiOrCustomEmoji (Evergreen.V251.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V251.Emoji.EmojiOrCustomEmoji (Evergreen.V251.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V251.Emoji.EmojiOrCustomEmoji (Evergreen.V251.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V251.Emoji.EmojiOrCustomEmoji (Evergreen.V251.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
