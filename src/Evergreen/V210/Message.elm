module Evergreen.V210.Message exposing (..)

import Array
import Evergreen.V210.Embed
import Evergreen.V210.Emoji
import Evergreen.V210.FileStatus
import Evergreen.V210.Id
import Evergreen.V210.NonemptySet
import Evergreen.V210.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V210.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V210.Emoji.EmojiOrCustomEmoji (Evergreen.V210.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V210.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V210.Id.Id Evergreen.V210.FileStatus.FileId) Evergreen.V210.FileStatus.FileData
    , embeds : Array.Array Evergreen.V210.Embed.Embed
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V210.Emoji.EmojiOrCustomEmoji (Evergreen.V210.NonemptySet.NonemptySet userId))
    | DeletedMessage Time.Posix


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
