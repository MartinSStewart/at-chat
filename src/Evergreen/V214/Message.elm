module Evergreen.V214.Message exposing (..)

import Array
import Evergreen.V214.Embed
import Evergreen.V214.Emoji
import Evergreen.V214.FileStatus
import Evergreen.V214.Id
import Evergreen.V214.NonemptySet
import Evergreen.V214.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V214.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V214.Emoji.EmojiOrCustomEmoji (Evergreen.V214.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V214.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V214.Id.Id Evergreen.V214.FileStatus.FileId) Evergreen.V214.FileStatus.FileData
    , embeds : Array.Array Evergreen.V214.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V214.Emoji.EmojiOrCustomEmoji (Evergreen.V214.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V214.Emoji.EmojiOrCustomEmoji (Evergreen.V214.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V214.Emoji.EmojiOrCustomEmoji (Evergreen.V214.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
