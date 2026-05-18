module Evergreen.V236.Message exposing (..)

import Array
import Evergreen.V236.Embed
import Evergreen.V236.Emoji
import Evergreen.V236.FileStatus
import Evergreen.V236.Id
import Evergreen.V236.NonemptySet
import Evergreen.V236.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V236.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V236.Emoji.EmojiOrCustomEmoji (Evergreen.V236.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V236.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V236.Id.Id Evergreen.V236.FileStatus.FileId) Evergreen.V236.FileStatus.FileData
    , embeds : Array.Array Evergreen.V236.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V236.Emoji.EmojiOrCustomEmoji (Evergreen.V236.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V236.Emoji.EmojiOrCustomEmoji (Evergreen.V236.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V236.Emoji.EmojiOrCustomEmoji (Evergreen.V236.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V236.Emoji.EmojiOrCustomEmoji (Evergreen.V236.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
