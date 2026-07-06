module Evergreen.V304.Message exposing (..)

import Array
import Evergreen.V304.Drawing
import Evergreen.V304.Embed
import Evergreen.V304.Emoji
import Evergreen.V304.FileStatus
import Evergreen.V304.Id
import Evergreen.V304.NonemptySet
import Evergreen.V304.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V304.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V304.Emoji.EmojiOrCustomEmoji (Evergreen.V304.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V304.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) Evergreen.V304.FileStatus.FileData
    , embeds : Array.Array Evergreen.V304.Embed.Embed
    , timestampDrawings : Evergreen.V304.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V304.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V304.Id.Id Evergreen.V304.FileStatus.FileId) (Evergreen.V304.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V304.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V304.Emoji.EmojiOrCustomEmoji (Evergreen.V304.NonemptySet.NonemptySet userId)) (Evergreen.V304.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V304.Emoji.EmojiOrCustomEmoji (Evergreen.V304.NonemptySet.NonemptySet userId)) (Evergreen.V304.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V304.Emoji.EmojiOrCustomEmoji (Evergreen.V304.NonemptySet.NonemptySet userId)) (Evergreen.V304.Drawing.Drawing userId) GameType


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
