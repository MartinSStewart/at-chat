module Evergreen.V283.Message exposing (..)

import Array
import Evergreen.V283.Embed
import Evergreen.V283.Emoji
import Evergreen.V283.FileStatus
import Evergreen.V283.Id
import Evergreen.V283.NonemptySet
import Evergreen.V283.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V283.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V283.Emoji.EmojiOrCustomEmoji (Evergreen.V283.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V283.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V283.Id.Id Evergreen.V283.FileStatus.FileId) Evergreen.V283.FileStatus.FileData
    , embeds : Array.Array Evergreen.V283.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V283.Emoji.EmojiOrCustomEmoji (Evergreen.V283.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V283.Emoji.EmojiOrCustomEmoji (Evergreen.V283.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V283.Emoji.EmojiOrCustomEmoji (Evergreen.V283.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V283.Emoji.EmojiOrCustomEmoji (Evergreen.V283.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
