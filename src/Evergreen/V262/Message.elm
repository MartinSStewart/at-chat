module Evergreen.V262.Message exposing (..)

import Array
import Evergreen.V262.Embed
import Evergreen.V262.Emoji
import Evergreen.V262.FileStatus
import Evergreen.V262.Id
import Evergreen.V262.NonemptySet
import Evergreen.V262.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V262.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V262.Emoji.EmojiOrCustomEmoji (Evergreen.V262.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V262.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V262.Id.Id Evergreen.V262.FileStatus.FileId) Evergreen.V262.FileStatus.FileData
    , embeds : Array.Array Evergreen.V262.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V262.Emoji.EmojiOrCustomEmoji (Evergreen.V262.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V262.Emoji.EmojiOrCustomEmoji (Evergreen.V262.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V262.Emoji.EmojiOrCustomEmoji (Evergreen.V262.NonemptySet.NonemptySet userId))
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V262.Emoji.EmojiOrCustomEmoji (Evergreen.V262.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
