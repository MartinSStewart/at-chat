module Evergreen.V305.Message exposing (..)

import Array
import Evergreen.V305.Drawing
import Evergreen.V305.Embed
import Evergreen.V305.Emoji
import Evergreen.V305.FileStatus
import Evergreen.V305.Id
import Evergreen.V305.NonemptySet
import Evergreen.V305.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V305.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V305.Emoji.EmojiOrCustomEmoji (Evergreen.V305.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V305.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.FileStatus.FileId) Evergreen.V305.FileStatus.FileData
    , embeds : Array.Array Evergreen.V305.Embed.Embed
    , timestampDrawings : Evergreen.V305.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V305.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V305.Id.Id Evergreen.V305.FileStatus.FileId) (Evergreen.V305.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V305.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V305.Emoji.EmojiOrCustomEmoji (Evergreen.V305.NonemptySet.NonemptySet userId)) (Evergreen.V305.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V305.Emoji.EmojiOrCustomEmoji (Evergreen.V305.NonemptySet.NonemptySet userId)) (Evergreen.V305.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V305.Emoji.EmojiOrCustomEmoji (Evergreen.V305.NonemptySet.NonemptySet userId)) (Evergreen.V305.Drawing.Drawing userId) GameType


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
