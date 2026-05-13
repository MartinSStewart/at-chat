module Evergreen.V215.Message exposing (..)

import Array
import Evergreen.V215.Embed
import Evergreen.V215.Emoji
import Evergreen.V215.FileStatus
import Evergreen.V215.Id
import Evergreen.V215.NonemptySet
import Evergreen.V215.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V215.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V215.Emoji.EmojiOrCustomEmoji (Evergreen.V215.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V215.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V215.Id.Id Evergreen.V215.FileStatus.FileId) Evergreen.V215.FileStatus.FileData
    , embeds : Array.Array Evergreen.V215.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V215.Emoji.EmojiOrCustomEmoji (Evergreen.V215.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V215.Emoji.EmojiOrCustomEmoji (Evergreen.V215.NonemptySet.NonemptySet userId))
    | CallEnded Time.Posix (SeqDict.SeqDict Evergreen.V215.Emoji.EmojiOrCustomEmoji (Evergreen.V215.NonemptySet.NonemptySet userId))


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
