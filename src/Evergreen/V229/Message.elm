module Evergreen.V229.Message exposing (..)

import Array
import Evergreen.V229.Embed
import Evergreen.V229.Emoji
import Evergreen.V229.FileStatus
import Evergreen.V229.Id
import Evergreen.V229.NonemptySet
import Evergreen.V229.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V229.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V229.Emoji.EmojiOrCustomEmoji (Evergreen.V229.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V229.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V229.Id.Id Evergreen.V229.FileStatus.FileId) Evergreen.V229.FileStatus.FileData
    , embeds : Array.Array Evergreen.V229.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V229.Emoji.EmojiOrCustomEmoji (Evergreen.V229.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V229.Emoji.EmojiOrCustomEmoji (Evergreen.V229.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V229.Emoji.EmojiOrCustomEmoji (Evergreen.V229.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V229.Emoji.EmojiOrCustomEmoji (Evergreen.V229.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
