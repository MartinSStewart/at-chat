module Evergreen.V293.Message exposing (..)

import Array
import Evergreen.V293.Drawing
import Evergreen.V293.Embed
import Evergreen.V293.Emoji
import Evergreen.V293.FileStatus
import Evergreen.V293.Id
import Evergreen.V293.NonemptySet
import Evergreen.V293.RichText
import List.Nonempty
import SeqDict
import Time


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V293.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V293.Emoji.EmojiOrCustomEmoji (Evergreen.V293.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V293.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) Evergreen.V293.FileStatus.FileData
    , embeds : Array.Array Evergreen.V293.Embed.Embed
    , timestampDrawings : Evergreen.V293.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V293.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V293.Id.Id Evergreen.V293.FileStatus.FileId) (Evergreen.V293.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V293.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V293.Emoji.EmojiOrCustomEmoji (Evergreen.V293.NonemptySet.NonemptySet userId)) (Evergreen.V293.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V293.Emoji.EmojiOrCustomEmoji (Evergreen.V293.NonemptySet.NonemptySet userId)) (Evergreen.V293.Drawing.Drawing userId)
    | GoMatchStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V293.Emoji.EmojiOrCustomEmoji (Evergreen.V293.NonemptySet.NonemptySet userId)) (Evergreen.V293.Drawing.Drawing userId)


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
