module Evergreen.V228.Message exposing (..)

import Array
import Evergreen.V228.Embed
import Evergreen.V228.Emoji
import Evergreen.V228.FileStatus
import Evergreen.V228.Id
import Evergreen.V228.NonemptySet
import Evergreen.V228.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V228.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V228.Emoji.EmojiOrCustomEmoji (Evergreen.V228.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V228.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V228.Id.Id Evergreen.V228.FileStatus.FileId) Evergreen.V228.FileStatus.FileData
    , embeds : Array.Array Evergreen.V228.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V228.Emoji.EmojiOrCustomEmoji (Evergreen.V228.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V228.Emoji.EmojiOrCustomEmoji (Evergreen.V228.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V228.Emoji.EmojiOrCustomEmoji (Evergreen.V228.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V228.Emoji.EmojiOrCustomEmoji (Evergreen.V228.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
