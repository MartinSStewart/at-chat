module Evergreen.V213.Message exposing (..)

import Array
import Evergreen.V213.Embed
import Evergreen.V213.Emoji
import Evergreen.V213.FileStatus
import Evergreen.V213.Id
import Evergreen.V213.NonemptySet
import Evergreen.V213.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V213.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V213.Emoji.EmojiOrCustomEmoji (Evergreen.V213.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V213.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V213.Id.Id Evergreen.V213.FileStatus.FileId) Evergreen.V213.FileStatus.FileData
    , embeds : Array.Array Evergreen.V213.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V213.Emoji.EmojiOrCustomEmoji (Evergreen.V213.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V213.Emoji.EmojiOrCustomEmoji (Evergreen.V213.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V213.Emoji.EmojiOrCustomEmoji (Evergreen.V213.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
