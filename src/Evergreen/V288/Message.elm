module Evergreen.V288.Message exposing (..)

import Array
import Evergreen.V288.Drawing
import Evergreen.V288.Embed
import Evergreen.V288.Emoji
import Evergreen.V288.FileStatus
import Evergreen.V288.Id
import Evergreen.V288.NonemptySet
import Evergreen.V288.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V288.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V288.Emoji.EmojiOrCustomEmoji (Evergreen.V288.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V288.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) Evergreen.V288.FileStatus.FileData
    , embeds : Array.Array Evergreen.V288.Embed.Embed
    , timestampDrawings : Evergreen.V288.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V288.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V288.Id.Id Evergreen.V288.FileStatus.FileId) (Evergreen.V288.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V288.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V288.Emoji.EmojiOrCustomEmoji (Evergreen.V288.NonemptySet.NonemptySet userId)) (Evergreen.V288.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V288.Emoji.EmojiOrCustomEmoji (Evergreen.V288.NonemptySet.NonemptySet userId)) (Evergreen.V288.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V288.Emoji.EmojiOrCustomEmoji (Evergreen.V288.NonemptySet.NonemptySet userId)) (Evergreen.V288.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
