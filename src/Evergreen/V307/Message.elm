module Evergreen.V307.Message exposing (..)

import Array
import Evergreen.V307.Drawing
import Evergreen.V307.Embed
import Evergreen.V307.Emoji
import Evergreen.V307.FileStatus
import Evergreen.V307.Id
import Evergreen.V307.NonemptySet
import Evergreen.V307.RichText
import List.Nonempty
import SeqDict
import Time


type GameType
    = GameType_Go
    | GameType_WordSpellingGame


type alias UserTextMessageData messageId userId =
    { createdAt : Time.Posix
    , createdBy : userId
    , content : List.Nonempty.Nonempty (Evergreen.V307.RichText.RichText userId)
    , reactions : SeqDict.SeqDict Evergreen.V307.Emoji.EmojiOrCustomEmoji (Evergreen.V307.NonemptySet.NonemptySet userId)
    , editedAt : Maybe Time.Posix
    , repliedTo : Maybe (Evergreen.V307.Id.Id messageId)
    , attachedFiles : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) Evergreen.V307.FileStatus.FileData
    , embeds : Array.Array Evergreen.V307.Embed.Embed
    , timestampDrawings : Evergreen.V307.Drawing.Drawing userId
    , userIconDrawings : Evergreen.V307.Drawing.Drawing userId
    , imageAttachmentDrawings : SeqDict.SeqDict (Evergreen.V307.Id.Id Evergreen.V307.FileStatus.FileId) (Evergreen.V307.Drawing.Drawing userId)
    , embedDrawings : SeqDict.SeqDict Int (Evergreen.V307.Drawing.Drawing userId)
    }


type Message messageId userId
    = UserTextMessage (UserTextMessageData messageId userId)
    | UserJoinedMessage Time.Posix userId (SeqDict.SeqDict Evergreen.V307.Emoji.EmojiOrCustomEmoji (Evergreen.V307.NonemptySet.NonemptySet userId)) (Evergreen.V307.Drawing.Drawing userId)
    | DeletedMessage Time.Posix
    | CallStarted Time.Posix (Maybe Time.Posix) userId (SeqDict.SeqDict Evergreen.V307.Emoji.EmojiOrCustomEmoji (Evergreen.V307.NonemptySet.NonemptySet userId)) (Evergreen.V307.Drawing.Drawing userId)
    | GameStarted Time.Posix userId (SeqDict.SeqDict Evergreen.V307.Emoji.EmojiOrCustomEmoji (Evergreen.V307.NonemptySet.NonemptySet userId)) (Evergreen.V307.Drawing.Drawing userId) GameType


type MessageState messageId userId
    = MessageLoaded (Message messageId userId)
    | MessageUnloaded
